class Tracker {
  final String id;
  String title;
  String petId;
  String ownerId;
  double longitude;
  double latitude;
  bool isDisabled;

  Tracker({
    required this.id,
    required this.title,
    required this.petId,
    required this.ownerId,
    required this.longitude,
    required this.latitude,
    required this.isDisabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'petId': petId,
      'ownerId': ownerId,
      'longitude': longitude,
      'latitude': latitude,
      'isDisabled': isDisabled,
    };
  }

  Tracker findById(String id) {
    return Tracker(
      id: id,
      title: title,
      petId: petId,
      ownerId: ownerId,
      longitude: longitude,
      latitude: latitude,
      isDisabled: isDisabled,
    );
  }

  Tracker copyWith({
    String? title,
    String? petId,
    String? ownerId,
    double? longitude,
    double? latitude,
    bool? isDisabled,
  }) {
    return Tracker(
      id: this.id,
      title: title ?? this.title,
      petId: petId ?? this.petId,
      ownerId: ownerId ?? this.ownerId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      isDisabled: isDisabled ?? this.isDisabled,
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
      isDisabled: data['isDisabled'] ?? false,
    );
  }
}
