import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tracker.dart';

class Trackers with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Tracker> _trackers = [];

  List<Tracker> get trackers {
    return [..._trackers];
  }

  Future<void> fetchAndSetTrackers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not found');
      }
      final userId = user.uid;
      final response = await _firestore
          .collection('trackers')
          .where('ownerId', isEqualTo: userId)
          .get();

      _trackers = response.docs.map((doc) {
        final data = doc.data();
        return Tracker.fromMap(data, doc.id);
      }).toList();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateTrackerDetails(Tracker tracker) async {
    final trackerRef = _firestore.collection('trackers').doc(tracker.id);

    try {
      await trackerRef.update(tracker.toMap());

      final docSnapshot = await trackerRef.get();
      final data = docSnapshot.data() as Map<String, dynamic>;

      // Here we handle potential null values in the data map
      final updatedTracker = Tracker.fromMap(data, tracker.id);

      final trackerIndex =
          _trackers.indexWhere((track) => track.id == updatedTracker.id);

      if (trackerIndex >= 0) {
        // The tracker already exists in the list, so update it
        _trackers[trackerIndex] = updatedTracker;
      } else {
        // The tracker doesn't exist in the list, so add it
        _trackers.add(updatedTracker);
      }

      notifyListeners();
    } catch (error) {
      print('Error updating tracker details: $error');
      throw error;
    }
  }

  Future<void> removeTracker(String trackerId) async {
    try {
      final trackerRef = _firestore.collection('trackers').doc(trackerId);

      await trackerRef.update({
        'ownerId': FieldValue.delete(),
        'title': FieldValue.delete(),
        'petId': FieldValue.delete(),
      });

      _trackers
          .removeWhere((existingTracker) => existingTracker.id == trackerId);
      notifyListeners();
    } catch (e) {
      print('Error removing tracker: $e');
      throw e;
    }
  }

  Future<bool> checkTrackerId(String trackerId) async {
    try {
      final docSnapshot =
          await _firestore.collection('trackers').doc(trackerId).get();
      return docSnapshot.exists;
    } catch (error) {
      throw error;
    }
  }

  Future<Tracker> fetchTrackerDetails(String trackerId) async {
    try {
      final docSnapshot =
          await _firestore.collection('trackers').doc(trackerId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        Tracker tracker = Tracker.fromMap(data, trackerId);
        return tracker;
      } else {
        throw Exception('Tracker not found');
      }
    } catch (error) {
      print('An error occurred while fetching tracker details: $error');
      throw error;
    }
  }
}
