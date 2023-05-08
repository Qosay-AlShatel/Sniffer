// fences.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/fence.dart';

class Fences with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Fence> _fences = [];

  List<Fence> get fences {
    return [..._fences];
  }

  Future<void> fetchAndSetFences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }
      final userId = user.uid; // Get the user ID from the authentication state
      final response = await FirebaseFirestore.instance
          .collection('fences')
          .where('creatorId', isEqualTo: userId)
          .get();

      _fences = response.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Fence.fromMap({...data, 'id': doc.id});
      }).toList();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addFence(Fence fence) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not found');
    }

    final fenceData = fence.toMap();
    await FirebaseFirestore.instance.collection('fences').add(fenceData);

    _fences.add(fence);
    notifyListeners();
  }
}
