import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tracker.dart';

class Trackers with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Tracker> _trackers = [];

  // Add a list to store active subscriptions
  List<StreamSubscription> _subscriptions = [];

  List<Tracker> get trackers {
    return [..._trackers];
  }

  Tracker findById(String id) {
    return _trackers.firstWhere((tracker) => tracker.id == id);
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
        // Listen to the document for real-time updates
        StreamSubscription subscription = _firestore
            .collection('trackers')
            .doc(doc.id)
            .snapshots()
            .listen((snapshot) {
          final data = snapshot.data() as Map<String, dynamic>;
          final updatedTracker = Tracker.fromMap(data, snapshot.id);
          // Update the tracker in the list
          int index = _trackers
              .indexWhere((tracker) => tracker.id == updatedTracker.id);
          if (index != -1) {
            _trackers[index] = updatedTracker;
            notifyListeners();
          } else {
            throw Exception('Tracker not found');
          }
        });

        // Add subscription to the list
        _subscriptions.add(subscription);

        final initialData = doc.data();
        return Tracker.fromMap(initialData, doc.id);
      }).toList();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  void cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  // void updateLocalTracker(Tracker updatedTracker) {
  //   int index =
  //       _trackers.indexWhere((tracker) => tracker.id == updatedTracker.id);
  //   if (index != -1) {
  //     _trackers[index] = updatedTracker;
  //     notifyListeners();
  //   } else {
  //     throw Exception('Tracker not found');
  //   }
  // }

  Future<void> updateTrackerDetails(
      Tracker tracker, BuildContext context) async {
    try {
      await _firestore
          .collection('trackers')
          .doc(tracker.id)
          .set(tracker.toMap());

      int index = _trackers
          .indexWhere((existingTracker) => existingTracker.id == tracker.id);
      if (index != -1) {
        _trackers[index] = tracker;
      } else {
        _trackers.add(tracker);
      }
      notifyListeners();
    } catch (error) {
      print('Error updating tracker: $error');
    }
  }

  Future<void> removeTracker(String trackerId) async {
    try {
      final trackerRef = _firestore.collection('trackers').doc(trackerId);

      await trackerRef.update({
        'ownerId': FieldValue.delete(),
        'title': FieldValue.delete(),
        'petId': FieldValue.delete(),
        'isDisabled': FieldValue.delete(),
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
