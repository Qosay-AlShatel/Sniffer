import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final int age;
  String imageUrl;
  final String description;
  final String ownerId;
  String fenceId; // New field for fenceId

  Pet({
    required this.id,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.description,
    required this.ownerId,
    required this.fenceId,
  });

  factory Pet.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    return Pet(
      id: document.id,
      name: data['name'],
      age: data['age'],
      imageUrl: data['imageUrl'],
      description: data['description'],
      ownerId: data['ownerId'],
      fenceId: data['fenceId'] ?? '',
    );
  }

  Pet copyWith({
    String? id,
    String? name,
    int? age,
    String? imageUrl,
    String? description,
    String? ownerId,
    String? fenceId,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      fenceId: fenceId ?? this.fenceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'imageUrl': imageUrl,
      'description': description,
      'ownerId': ownerId,
      'fenceId': fenceId,
    };
  }
}
