import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/fences.dart';
import '../models/fence.dart';

class NewFenceForm extends StatefulWidget {
  @override
  _NewFenceFormState createState() => _NewFenceFormState();
}

class _NewFenceFormState extends State<NewFenceForm> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  bool _isMapRendered = false;

  final Completer<void> _mapRenderedCompleter = Completer<void>();
  final _formKey = GlobalKey<FormState>();
  String _fenceTitle = '';
  List<LatLng> _fenceCoordinates = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  late Future<LatLng> _initLocation;
  late LatLng pointCache;

  @override
  void initState() {
    super.initState();
    _initLocation = _getCurrentLocation();
  }

  bool _segmentsIntersect(
      vm.Vector2 p1, vm.Vector2 q1, vm.Vector2 p2, vm.Vector2 q2) {
    final p1ToQ1 = q1 - p1;
    final p1ToP2 = p2 - p1;
    final p1ToQ2 = q2 - p1;
    final p2ToQ2 = q2 - p2;
    final p2ToP1 = p1 - p2;
    final p2ToQ1 = q1 - p2;

    final cross1 = p1ToQ1.cross(p1ToP2) * p1ToQ1.cross(p1ToQ2);
    final cross2 = p2ToQ2.cross(p2ToP1) * p2ToQ2.cross(p2ToQ1);

    return cross1 < 0 && cross2 < 0;
  }

  GoogleMapController? _mapController;

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

  //@TODO add something to let user know they've reached maximum taps/less than minimum taps
  void _onMapTapped(LatLng latLng) {
    if (_fenceCoordinates.length >= 8) {
      // Only allow eight points maximum
      return;
    }

    setState(() {
      _fenceCoordinates.add(latLng);
      _markers.add(
        Marker(
          markerId: MarkerId(latLng.toString()),
          position: latLng,
        ),
      );
      //Cache the added point for undo/redo
      pointCache = latLng;
      // Update the polygon if there are at least 3 points
      if (_fenceCoordinates.length >= 3) {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId('geofence'),
          points: _fenceCoordinates,
          strokeWidth: 2,
          strokeColor: Colors.deepPurple,
          fillColor: Colors.deepPurple.withOpacity(0.2),
        ));
      }
    });
  }
  void removePoint() {
    setState(() {
      if(_fenceCoordinates.isNotEmpty) {
        pointCache = _fenceCoordinates.removeLast();
      }
      if (_fenceCoordinates.length >= 3) {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId('geofence'),
          points: _fenceCoordinates,
          strokeWidth: 2,
          strokeColor: Colors.deepPurple,
          fillColor: Colors.deepPurple.withOpacity(0.2),
        ));
      }
    });
  }

  void redoPoint() {
      _onMapTapped(pointCache);
  }

  bool _isSelfIntersecting() {
    for (int i = 0; i < _fenceCoordinates.length; i++) {
      final p1 = vm.Vector2(
        _fenceCoordinates[i].latitude,
        _fenceCoordinates[i].longitude,
      );
      final q1 = vm.Vector2(
        _fenceCoordinates[(i + 1) % _fenceCoordinates.length].latitude,
        _fenceCoordinates[(i + 1) % _fenceCoordinates.length].longitude,
      );

      for (int j = i + 1; j < _fenceCoordinates.length; j++) {
        final p2 = vm.Vector2(
          _fenceCoordinates[j].latitude,
          _fenceCoordinates[j].longitude,
        );
        final q2 = vm.Vector2(
          _fenceCoordinates[(j + 1) % _fenceCoordinates.length].latitude,
          _fenceCoordinates[(j + 1) % _fenceCoordinates.length].longitude,
        );

        if (_segmentsIntersect(p1, q1, p2, q2)) {
          return true;
        }
      }
    }

    return false;
  }

  GlobalKey _mapKey = GlobalKey();
  ui.Image? mapSnapshot;

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_fenceCoordinates.length < 3 || _isSelfIntersecting()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invalid Geofence'),
          content: Text('Please select at least 3 non-intersecting points.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      ).then((_) => {
            setState(() {
              _fenceCoordinates.clear();
              _markers.clear();
              _polygons.clear();
            })
          });
      return;
    }

    FocusScope.of(context).unfocus();

    _formKey.currentState!.save();

    // Before taking the snapshot, adjust the map view to include the entire geofence.
    if (_mapController != null && _fenceCoordinates.isNotEmpty) {
      // Compute the bounds of the geofence.
      double southwestLatitude = _fenceCoordinates[0].latitude;
      double southwestLongitude = _fenceCoordinates[0].longitude;
      double northeastLatitude = _fenceCoordinates[0].latitude;
      double northeastLongitude = _fenceCoordinates[0].longitude;

      for (var coordinate in _fenceCoordinates) {
        if (coordinate.latitude <= southwestLatitude) {
          southwestLatitude = coordinate.latitude;
        }
        if (coordinate.longitude <= southwestLongitude) {
          southwestLongitude = coordinate.longitude;
        }
        if (coordinate.latitude >= northeastLatitude) {
          northeastLatitude = coordinate.latitude;
        }
        if (coordinate.longitude >= northeastLongitude) {
          northeastLongitude = coordinate.longitude;
        }
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(southwestLatitude, southwestLongitude),
        northeast: LatLng(northeastLatitude, northeastLongitude),
      );

      // Update the map camera to include the bounds.
      CameraUpdate cameraUpdate =
          CameraUpdate.newLatLngBounds(bounds, 130); // 50 pixels padding
      await _mapController!.moveCamera(cameraUpdate);

      // Allow some time for map to complete camera animation
      await Future.delayed(Duration(milliseconds: 500));
    }
    _setLoading(true);

    // Take a snapshot of the map
    Uint8List? mapSnapshotBytes = await _mapController!.takeSnapshot();

    if (mapSnapshotBytes != null) {
      // Upload the snapshot to Firebase Storage
      String imageUrl = await _uploadFenceImage(mapSnapshotBytes);

      final fence = Fence(
        id: DateTime.now().toIso8601String(),
        title: _fenceTitle,
        imageUrl: imageUrl,
        creatorId: FirebaseAuth.instance.currentUser!.uid,
        coordinates: _fenceCoordinates,
      );
      // Add fence using the provider
      await Provider.of<Fences>(context, listen: false).addFence(fence);
      Navigator.of(context).pop();
      _setLoading(false);
    } else {
      _setLoading(false);
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking snapshot of the map.'),
        ),
      );
    }
  }

  Future<String> _uploadFenceImage(Uint8List imageBytes) async {
    // Generate a unique file name for the image
    String fileName = 'fences/${DateTime.now().toIso8601String()}.png';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

    // Upload the image to Firebase Storage
    UploadTask uploadTask = storageRef.putData(imageBytes);

    // Get the image URL
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    return imageUrl;
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_isMapRendered) {
      _mapRenderedCompleter.complete();
      _isMapRendered = true;
    }
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            title: Text('Add New Fence'),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () async {
                    _onSubmit();
                  }),
            ],
          ),
          body: FutureBuilder<LatLng>(
            future: _initLocation,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              return Stack(
                children: [
                  RepaintBoundary(
                    key: _mapKey,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      onTap: _onMapTapped,
                      //markers: _markers,
                      polygons: _polygons,
                      initialCameraPosition: CameraPosition(
                        target: snapshot.data!,
                        zoom: 17,
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                                labelText: 'Fence Title',
                                border: OutlineInputBorder(),
                                focusColor: Colors.deepPurple.withOpacity(0.2)),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter a fence title';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _fenceTitle = value!;
                            },
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tap on the map to add points for your fence.',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple[300]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple[200],
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12)
                          ),
                          onPressed: removePoint,
                          child: Icon(Icons.arrow_back),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple[200],
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12)
                          ),
                          onPressed: redoPoint,
                          child: Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ),

                ],
              );
            },
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
