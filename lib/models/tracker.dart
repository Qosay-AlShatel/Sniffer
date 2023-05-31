class Tracker {
  final String id;
  String title;
  String petId;
  String ownerId;
  double longitude;
  double latitude;

  Tracker({
    required this.id,
    required this.title,
    required this.petId,
    required this.ownerId,
    required this.longitude,
    required this.latitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'petId': petId,
      'ownerId': ownerId,
      'longitude': longitude,
      'latitude': latitude
    };
  }

  Tracker copyWith({
    String? title,
    String? petId,
    String? ownerId,
    double? longitude,
    double? latitude,
  }) {
    return Tracker(
      id: this.id,
      title: title ?? this.title,
      petId: petId ?? this.petId,
      ownerId: ownerId ?? this.ownerId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
    );
  }

  // Create a Tracker instance from a Map fetched from Firestore
  static Tracker fromMap(Map<String, dynamic> data, String id) {
    return Tracker(
      id: id,
      title: data['title'] ?? '',
      petId: data['petId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      longitude: data['longitude'] ?? 0.0,
      latitude: data['latitude'] ?? 0.0,
    );
  }
}
