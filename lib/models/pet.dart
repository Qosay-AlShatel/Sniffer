import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final int age;
  final String imageUrl;
  final String description;
  final String ownerId;

  Pet({
    required this.id,
    required this.name,
    required this.age,
    required this.imageUrl,
    required this.description,
    required this.ownerId,
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
    );
  }
}
