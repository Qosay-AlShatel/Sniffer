import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../providers/pets.dart';
import '../providers/fences.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Future<Marker> marker;
  bool _isLoading = false;

  late GoogleMapController _mapController;
  String? _selectedTracker;
  Set<Marker> markers = {};
  Set<Polygon> polygons = {};

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
  }

  void _updateMarkersAndPolygons() {
    var trackersProvider = Provider.of<Trackers>(context, listen: false);
    var petsProvider = Provider.of<Pets>(context, listen: false);
    var fencesProvider = Provider.of<Fences>(context, listen: false);

    // Clear the existing markers and polygons first
    markers.clear();
    polygons.clear();

    // Create a marker and polygon for the selected tracker, if any
    if (_selectedTracker != null) {
      var tracker = trackersProvider.trackers
          .firstWhere((tracker) => tracker.id == _selectedTracker);

      markers.add(Marker(
        markerId: MarkerId(tracker.id),
        position: LatLng(tracker.latitude, tracker.longitude),
        infoWindow: InfoWindow(title: tracker.title),
      ));

      var pet = petsProvider.findById(tracker.petId);
      if (pet != null) {
        var fence = fencesProvider.findById(pet.fenceId);
        if (fence != null) {
          polygons.add(Polygon(
            polygonId: PolygonId(fence.id),
            points: fence.coordinates
                .map((v) => LatLng(v.latitude, v.longitude))
                .toList(),
            strokeColor: Colors.red,
            strokeWidth: 1,
            fillColor: Colors.red.withOpacity(0.5),
          ));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    var trackers = Provider.of<Trackers>(context).trackers;

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
                            zoom: 14.0,
                          ),
                          markers: markers,
                          polygons: polygons,
                        );
                      }
                    } else {
                      // While the future is not resolved, return empty container or loading spinner
                      return Container();
                    }
                  },
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
                    Future.delayed(Duration.zero, () {
                      _updateMarkersAndPolygons();

                      var selectedTracker = trackers.firstWhere(
                          (tracker) => tracker.id == _selectedTracker);
                      _mapController.moveCamera(
                        CameraUpdate.newLatLng(
                          LatLng(selectedTracker.latitude,
                              selectedTracker.longitude),
                        ),
                      );
                      _mapController.moveCamera(CameraUpdate.zoomTo(17.0));
                    });
                  },
                ),
              ),
            ),
          );
  }
}
