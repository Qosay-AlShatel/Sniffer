import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/fence.dart';

class Fences with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Fence> _fences = [];

  List<Fence> get fences {
    return [..._fences];
  }

  Fence? findById(String id) {
    try {
      return _fences.firstWhere((fence) => fence.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchAndSetFences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }
      final userId = user.uid;
      final response = await _firestore
          .collection('fences')
          .where('creatorId', isEqualTo: userId)
          .get();

      _fences = response.docs.map((doc) {
        final data = doc.data();
        return Fence.fromMap({...data, 'id': doc.id});
      }).toList();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> deleteFence(Fence fence, BuildContext context) async {
    print('Deleting fence with id: ${fence.id}');

    try {
      DocumentSnapshot docSnap = await FirebaseFirestore.instance
          .collection('fences')
          .doc(fence.id)
          .get();

      if (!docSnap.exists) {
        print('No document found with id: ${fence.id}');
        return;
      }

      await docSnap.reference.delete();
      print('Deleted fence document successfully.');

      Map<String, dynamic> data = docSnap.data()
          as Map<String, dynamic>; // Casting to Map<String, dynamic>
      String imageUrl = data['imageUrl']; // Accessing the imageUrl

      final refFromUrl = FirebaseStorage.instance.refFromURL(imageUrl);
      await refFromUrl.delete();
      print('Deleted fence image successfully.');

      Navigator.pop(context);
    } catch (e) {
      print('Error deleting fence: $e');
    }

    _fences.removeWhere((existingFence) => existingFence.id == fence.id);
    notifyListeners();
  }

  Future<void> addFence(Fence fence) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }

      final fenceData = fence.toMap();

      final docRef = await _firestore.collection('fences').add(fenceData);
      // Update the fence ID with the document ID from Firebase
      final updatedFence = fence.copyWith(id: docRef.id);

      _fences.add(updatedFence);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }
}
