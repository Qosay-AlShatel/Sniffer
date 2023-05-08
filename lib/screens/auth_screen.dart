import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/auth_form.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  var _isLoading = false;

  void _submitAuthForm(
    String email,
    String password,
    String userFirstName,
    String userLastName,
    bool isLogin,
    BuildContext ctx,
  ) async {
    UserCredential authResult;
    try {
      setState(() {
        _isLoading = true;
      });
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
    } on FirebaseAuthException catch (err) {
      String message = 'An error occurred, please check your credentials!';
      switch (err.code) {
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'email-already-in-use':
          message = 'The email address is already in use by another account.';
          break;
        case 'wrong-password':
          message =
              'The password is invalid or the user does not have a password.';
          break;
        case 'user-not-found':
          message = 'There is no user record corresponding to this email.';
          break;
      }

      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(ctx).colorScheme.error,
      ));
      setState(() {
        print('Setting _isLoading to false after FirebaseAuthException');
        _isLoading = false;
      });
    } catch (err) {
      print(err.toString());
      if (mounted)
        setState(() {
          print('Setting _isLoading to false after general exception');
          _isLoading = false;
        });
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    TextEditingController emailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Please enter your email address to receive a password reset link.'),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Send Email'),
              onPressed: () async {
                await _sendForgotPasswordEmail(emailController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendForgotPasswordEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print('Password reset email sent to $email');
    } on FirebaseAuthException catch (err) {
      print('Error sending password reset email: ${err.message}');
    } catch (err) {
      print('Unknown error: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(_submitAuthForm, _isLoading, _showForgotPasswordDialog);
  }
}
