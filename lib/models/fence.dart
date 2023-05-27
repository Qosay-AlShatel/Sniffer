import 'package:google_maps_flutter/google_maps_flutter.dart';

class Fence {
  final String id;
  final String title;
  final String imageUrl;
  final String creatorId;
  final List<LatLng> coordinates;

  Fence({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.creatorId,
    required this.coordinates,
  });

  Fence copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? creatorId,
    List<LatLng>? coordinates,
  }) {
    return Fence(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      creatorId: creatorId ?? this.creatorId,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  // Convert a Fence instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'coordinates': coordinates
          .map((coord) => {
                'latitude': coord.latitude,
                'longitude': coord.longitude,
              })
          .toList(),
    };
  }

  // Create a Fence instance from a Map fetched from Firestore
  factory Fence.fromMap(Map<String, dynamic> data) {
    return Fence(
      id: data['id'],
      title: data['title'],
      imageUrl: data['imageUrl'],
      creatorId: data['creatorId'],
      coordinates: (data['coordinates'] as List)
          .map((coord) => LatLng(coord['latitude'], coord['longitude']))
          .toList(),
    );
  }
}
