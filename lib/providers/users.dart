import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Users with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> submitAuthForm(
    String email,
    String password,
    String userFirstName,
    String userLastName,
    bool isLogin,
  ) async {
    UserCredential authResult;
    try {
      _isLoading = true;
      notifyListeners();
      if (isLogin) {
        authResult = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        authResult = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        authResult.user?.sendEmailVerification();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user?.uid)
            .set(
          {
            'first name': userFirstName,
            'last name': userLastName,
            'email': email,
          },
        );
      }
      print('Authentication process completed. User: ${authResult.user}');
    } on FirebaseAuthException {
      // handle error in UI
    } catch (err) {
      print(err.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendForgotPasswordEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } on FirebaseAuthException catch (err) {
      print('Error sending password reset email: ${err.message}');
    } catch (err) {
      print('Unknown error: $err');
    }
  }
}
