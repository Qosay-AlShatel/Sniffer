import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';

class Pets with ChangeNotifier {
  List<Pet> _pets = [];

  final String ownerId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Pets(this.ownerId, [List<Pet>? initialPets]) {
    if (initialPets != null) {
      _pets = initialPets;
    }
  }

  List<Pet> get pets {
    return [..._pets];
  }

  Pet findById(String id) {
    return _pets.firstWhere((pet) => pet.id == id);
  }

  Future<List<Pet>> fetchPets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in.');

      return []; // Return an empty list if no user is logged in
    }

    try {
      final response = await _firestore
          .collection('pets')
          .where('ownerId', isEqualTo: user.uid) // Filter pets by ownerId
          .get();
      final pets = response.docs.map((doc) {
        return Pet(
          id: doc.id,
          name: doc['name'],
          age: doc['age'],
          description: doc['description'],
          imageUrl: doc['imageUrl'],
          ownerId: user.uid,
        );
      }).toList();
      _pets = pets;
      notifyListeners();
      print('Fetched pets: ${pets.length}');

      return pets; // Return the list of pets
    } catch (error) {
      print('Error fetching pets: $error');

      throw (error);
    }
  }

  void addPet(Pet pet) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final newPet = Pet(
      id: DateTime.now().toString(),
      name: pet.name,
      age: pet.age,
      imageUrl: pet.imageUrl,
      description: pet.description,
      ownerId: user.uid,
    );

    final petsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets');
    await petsRef.doc(newPet.id).set({
      'name': newPet.name,
      'age': newPet.age,
      'imageUrl': newPet.imageUrl,
      'description': newPet.description,
      'ownerId': user.uid,
    });

    _pets.add(newPet);
    notifyListeners();

    await fetchPets();
  }

  void updatePet(String id, Pet newPet) {
    final petIndex = _pets.indexWhere((pet) => pet.id == id);
    if (petIndex >= 0) {
      _pets[petIndex] = newPet;
      notifyListeners();
    } else {
      print('...');
    }
  }

  void deletePet(String id) {
    _pets.removeWhere((pet) => pet.id == id);
    notifyListeners();
  }

  void clearPets() {
    _pets = [];
    notifyListeners();
  }
}
