import 'dart:ui' as ui;
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/fences.dart';
import '../models/fence.dart';

class NewFenceForm extends StatefulWidget {
  @override
  _NewFenceFormState createState() => _NewFenceFormState();
}

class _NewFenceFormState extends State<NewFenceForm> {
  bool _isMapRendered = false;

  final Completer<void> _mapRenderedCompleter = Completer<void>();
  final _formKey = GlobalKey<FormState>();
  String _fenceTitle = '';
  List<LatLng> _fenceCoordinates = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};

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

  Future<void> _captureAndUploadMapImage() async {
    // Add a delay before capturing the image
    await Future.delayed(Duration(milliseconds: 500));

    RenderRepaintBoundary boundary =
        _mapKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData byteData =
        await image.toByteData(format: ui.ImageByteFormat.png) as ByteData;
    Uint8List pngBytes = byteData.buffer.asUint8List();

    // Save image to device
    Directory tempDir = await getTemporaryDirectory();
    File file = await new File('${tempDir.path}/map_snapshot.png').create();
    await file.writeAsBytes(pngBytes);

    // Upload image to Firebase Storage
    String fileName = 'fences/map_snapshot_${DateTime.now()}.png';
    Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = firebaseStorageRef.putFile(file);
    await uploadTask;
  }

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

  void _onMapTapped(LatLng latLng) {
    if (_fenceCoordinates.length >= 6) {
      // Only allow six points maximum
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

      // Update the polygon if there are at least 3 points
      if (_fenceCoordinates.length >= 3) {
        _polygons.clear();
        _polygons.add(Polygon(
          polygonId: PolygonId('geofence'),
          points: _fenceCoordinates,
          strokeWidth: 2,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.2),
        ));
      }
    });
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
    final user = FirebaseAuth.instance.currentUser;

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

    _formKey.currentState!.save();

    // Take a snapshot of the map
    Uint8List? mapSnapshotBytes = await _mapController!.takeSnapshot();

    if (mapSnapshotBytes != null) {
      // Upload the snapshot to Firebase Storage
      String imageUrl = await _uploadFenceImage(mapSnapshotBytes);

      final fence = Fence(
        title: _fenceTitle,
        imageUrl: imageUrl,
        creatorId: user!.uid,
        coordinates: _fenceCoordinates,
      );
      Provider.of<Fences>(context, listen: false).addFence(fence);
      Navigator.of(context).pop();
    } else {
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text('Add New Fence'),
        leading: IconButton(onPressed: ()=> Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),),
        actions: [
          IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                _onSubmit();
              }),
        ],
      ),
      body: FutureBuilder<LatLng>(
        future: _getCurrentLocation(),
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
                  markers: _markers,
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
                          border: OutlineInputBorder(
                          ),
                          focusColor: Colors.deepPurple.withOpacity(0.2)
                        ),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple[300]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}