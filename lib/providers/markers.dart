import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Markers with ChangeNotifier {
  List<Marker> _markers = [];
  List<Polygon> _polygons = [];

  List<Marker> get markers {
    return [..._markers];
  }

  List<Polygon> get polygons {
    return [..._polygons];
  }

  void addMarker(Marker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void addPolygon(Polygon polygon) {
    _polygons.add(polygon);
    notifyListeners();
  }

  void clearPolygons() {
    _polygons.clear();
    notifyListeners();
  }
}
