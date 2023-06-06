import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../providers/pets.dart';
import '../providers/fences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:point_in_polygon/point_in_polygon.dart';

class MapPage extends StatefulWidget {
  final String? trackerId;
  MapPage({this.trackerId});
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<Marker> marker;
  bool _isLoading = false;
  bool _isOutsideGeofence = false;
  MapType _currentMapType = MapType.normal;

  late GoogleMapController _mapController;
  String? _selectedTracker;
  Set<Marker> markers = {};
  Set<Polygon> polygons = {};
  late Polygon selectedPolygonFence;

  Future<LatLng> _getCurrentLocation() async {
    // Request location permission
    PermissionStatus permissionStatus = await Permission.location.request();

    // Check if permission is granted
    if (permissionStatus.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } else {
      // Return a default location when permission is denied
      return LatLng(0, 0);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedTracker != null) {
      final tracker = Provider.of<Trackers>(context, listen: false)
          .findById(_selectedTracker!);
      _mapController.moveCamera(CameraUpdate.newLatLng(
        LatLng(tracker.latitude, tracker.longitude),
      ));
      _mapController.moveCamera(CameraUpdate.zoomTo(17.0));
    }
  }

  void _updateMarkersAndPolygons() {
    // Clear the existing markers and polygons first
    markers.clear();
    polygons.clear();

    // Check if a tracker is selected
    if (_selectedTracker != null) {
      // Get the selected tracker
      var tracker = Provider.of<Trackers>(context, listen: false)
          .findById(_selectedTracker!);

      markers.add(Marker(
        markerId: MarkerId(tracker.id),
        position: LatLng(tracker.latitude, tracker.longitude),
        infoWindow: InfoWindow(title: tracker.title),
      ));

      // Get the pet associated with the tracker
      var pet =
          Provider.of<Pets>(context, listen: false).findById(tracker.petId);
      if (pet != null) {
        // Get the fence associated with the pet
        var fence =
            Provider.of<Fences>(context, listen: false).findById(pet.fenceId);
        if (fence != null) {
          // Add polygon for the selected fence
          selectedPolygonFence = Polygon(
            polygonId: PolygonId(fence.id),
            points: fence.coordinates
                .map((v) => LatLng(v.latitude, v.longitude))
                .toList(),
            strokeColor: Colors.deepPurple,
            strokeWidth: 1,
            fillColor: Colors.deepPurple.withOpacity(0.5),
          );
          polygons.add(selectedPolygonFence);
          Point current = Point(x: tracker.longitude, y: tracker.latitude);
          _isOutsideGeofence = _checkGeofence(current, selectedPolygonFence);
        }
      }
    }
  }

  @override
  void initState() {
    print('id  =  ${widget.trackerId}');

    super.initState();
    _selectedTracker = widget.trackerId;
    _requestPermission();
    setState(() {
      _isLoading = true;
    });

    marker = _createInitialMarker();
    Provider.of<Trackers>(context, listen: false)
        .fetchAndSetTrackers()
        .then((_) {
      Provider.of<Fences>(context, listen: false).fetchAndSetFences().then((_) {
        _updateMarkersAndPolygons();
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  Future<Marker> _createInitialMarker() async {
    LatLng initialPosition = await _getCurrentLocation();
    return Marker(
      markerId: MarkerId('1'),
      position: initialPosition,
      infoWindow: InfoWindow(title: 'My Location'),
    );
  }

  void _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();

    final info = statuses[Permission.location].toString();
    print('Location Permission Status: $info');
  }
  bool _checkGeofence(Point point, Polygon polygon) {
    print('CHECKING GEOFENCE!');
    final List<LatLng> pointsLatLng = polygon.points;
    final List<Point> points = pointsLatLng.map((latLng) {
      return Point(x: latLng.latitude, y: latLng.longitude);
    }).toList();
    return !Poly.isPointInPolygon(point, points);
  }


  @override
  Widget build(BuildContext context) {
    var trackers = Provider.of<Trackers>(context).trackers;
    _updateMarkersAndPolygons();
    List<DropdownMenuItem<String>> dropdownItems = trackers.map((tracker) {
      return DropdownMenuItem(
        child: Text(tracker.title),
        value: tracker.id,
      );
    }).toList();

    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
            color: Colors.deepPurple[300],
          ))
        : Scaffold(
            body: Stack(
              children: <Widget>[
                FutureBuilder<Marker>(
                  future: marker,
                  builder:
                      (BuildContext context, AsyncSnapshot<Marker> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        // Add initial marker to the set of other markers
                        markers.add(snapshot.data!);

                        return GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: snapshot.data!.position,
                            zoom: 17.0,
                          ),
                          markers: markers,
                          polygons: polygons,
                          mapType: _currentMapType,
                        );
                      }
                    } else {
                      // While the future is not resolved, return empty container or loading spinner
                      return Container();
                    }
                  },
                ),
                Positioned(
                  left: 10,
                  bottom: 50,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _currentMapType = _currentMapType == MapType.normal
                            ? MapType.satellite
                            : MapType.normal;
                      });
                    },
                    child: Icon(Icons.map),
                  ),
                ),
                ),
                if(_isOutsideGeofence)
                      Center(
                        child: Text("You pet is outside the geofence!",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      )
                )
              ],
            ),
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedTracker,
                  items: dropdownItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedTracker = value;
                    });
                    Future.delayed(
                      Duration.zero,
                      () {
                        _updateMarkersAndPolygons();

                        final trackers =
                            Provider.of<Trackers>(context, listen: false)
                                .trackers;
                        var selectedTracker = trackers.firstWhere(
                            (tracker) => tracker.id == _selectedTracker);
                        _mapController.moveCamera(
                          CameraUpdate.newLatLng(
                            LatLng(selectedTracker.latitude,
                                selectedTracker.longitude),
                          ),
                        );
                        _mapController.moveCamera(
                          CameraUpdate.zoomTo(17.5),
                        );
                        Point point = Point(x: selectedTracker.latitude,
                            y:selectedTracker.longitude);
                        _isOutsideGeofence = _checkGeofence(point, selectedPolygonFence);
                      },
                    );
                  },
                ),
              ),
            ),
          );
  }
}
