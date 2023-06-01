import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Pet? findById(String id) {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (_) {
      return null;
    }
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
          fenceId: doc['fenceId'] ??
              '', // fetch fenceId from the doc, defaults to an empty string if not provided
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

  Future<Pet> addPet(Pet pet) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: No user logged in.");
      throw Exception('No user logged in');
    }

    final newPet = Pet(
      id: DateTime.now().toString(),
      name: pet.name,
      age: pet.age,
      imageUrl: pet.imageUrl,
      description: pet.description,
      ownerId: user.uid,
      fenceId: pet.fenceId, // assign fenceId to the new pet
    );

    DocumentReference docRef;
    try {
      docRef = await _firestore.collection('pets').add({
        'name': newPet.name,
        'age': newPet.age,
        'imageUrl': newPet.imageUrl,
        'description': newPet.description,
        'ownerId': user.uid,
        'fenceId': newPet.fenceId, // store fenceId in Firestore
      });
    } catch (error) {
      print('Error adding pet to Firestore: $error');
      throw error;
    }

    final createdPet = Pet(
      id: docRef.id,
      name: newPet.name,
      age: newPet.age,
      imageUrl: newPet.imageUrl,
      description: newPet.description,
      ownerId: user.uid,
      fenceId: newPet.fenceId,
    );

    _pets.add(createdPet);
    notifyListeners();

    try {
      await fetchPets();
    } catch (error) {
      print('Error fetching pets after add: $error');
      throw error;
    }

    print('Pet added successfully: ${createdPet.id}');
    return createdPet;
  }

  void updatePet(String id, Pet newPet, String fenceId) {
    // add fenceId as a parameter to updatePet method
    final petIndex = _pets.indexWhere((pet) => pet.id == id);
    if (petIndex >= 0) {
      _pets[petIndex] =
          newPet.copyWith(fenceId: fenceId); // assign new fenceId to the pet
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

  Future<String> uploadImage(File imageFile) async {
    String fileName = 'pets/${DateTime.now().toIso8601String()}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    final UploadTask uploadTask = storageRef.putFile(imageFile);

    await uploadTask.whenComplete(() {});
    final String downloadUrl = await storageRef.getDownloadURL();

    return downloadUrl;
  }
}
