import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Name: ${user.displayName}'),
            Text('Email: ${user.email}'),
            // Add more fields as needed
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement editing functionality here
              },
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
