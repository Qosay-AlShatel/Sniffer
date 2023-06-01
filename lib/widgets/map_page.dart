import 'package:flutter/material.dart';
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
  late GoogleMapController _mapController;
  String? _selectedTracker;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
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
    var trackersProvider = Provider.of<Trackers>(context);
    var petsProvider = Provider.of<Pets>(context);
    var fencesProvider = Provider.of<Fences>(context);
    var trackers = trackersProvider.trackers;

    Set<Marker> markers = Set.from(trackers.map((tracker) {
      return Marker(
        markerId: MarkerId(tracker.id),
        position: LatLng(tracker.latitude, tracker.longitude),
        infoWindow: InfoWindow(title: tracker.title),
      );
    }));

    Set<Polygon> polygons = {};
    for (var tracker in trackers) {
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

    List<DropdownMenuItem<String>> dropdownItems = trackers.map((tracker) {
      return DropdownMenuItem(
        child: Text(tracker.title),
        value: tracker.id,
      );
    }).toList();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(trackers[0].latitude, trackers[0].longitude),
              zoom: 11.0,
            ),
            markers: markers,
            polygons: polygons,
          ),
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
              var selectedTracker =
                  trackers.firstWhere((tracker) => tracker.id == value);
              _mapController.moveCamera(
                CameraUpdate.newLatLng(
                  LatLng(selectedTracker.latitude, selectedTracker.longitude),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
