import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const routeName = '/user-profile';
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  final _currentUser = FirebaseAuth.instance.currentUser!;

  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _firstNameController.text =
        _currentUser.displayName?.split(' ').first ?? '';
    _lastNameController.text = _currentUser.displayName?.split(' ').last ?? '';
    _emailController.text = _currentUser.email ?? '';
  }

  File? pickedImage;
  Future<void> _selectImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final pickedImageFile = await _picker.pickImage(
      imageQuality: 50,
      maxWidth: 150,
      source: ImageSource.gallery,
    );

    setState(() {
      if (pickedImageFile != null) {
        pickedImage = File(pickedImageFile.path);
      }
    });
  }

  Future<String> _uploadImage(File imageFile) async {
    String fileName = 'users/${DateTime.now().toIso8601String()}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    final UploadTask uploadTask = storageRef.putFile(imageFile);

    await uploadTask.whenComplete(() {});
    final String downloadUrl = await storageRef.getDownloadURL();

    return downloadUrl;
  }

  Future<void> _saveChanges() async {
    String imageUrl;
    try {
      imageUrl = await _uploadImage(pickedImage!);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $error')),
      );
      _setLoading(false);
      return;
    }
    if (_formKey.currentState!.validate()) {
      try {
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        if (email.isNotEmpty && email != _currentUser.email) {
          // Verify new email if it's changed
          await _currentUser.verifyBeforeUpdateEmail(email);
        }

        if (firstName.isNotEmpty && lastName.isNotEmpty) {
          await _firestore.collection('users').doc(_currentUser.uid).update({
            'first name': firstName,
            'last name': lastName,
          });

          if (imageUrl.isNotEmpty) {
            await _firestore.collection('users').doc(_currentUser.uid).update({
              'imageUrl': imageUrl,
            });
            _currentUser.updatePhotoURL(imageUrl);
          }
          // Update display name
          final displayName = '$firstName $lastName';
          await _currentUser.updateDisplayName(displayName);
        }

        if (password.isNotEmpty) {
          // Update password if it's not empty
          await _currentUser.updatePassword(password);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

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
                    'Please enter your email address to receive a password reset link.',
                    style: TextStyle(color: Colors.black),
                  ),
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
                child:
                    Text('Cancel', style: TextStyle(color: Colors.deepPurple)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.all(8.0)),
                child: Text(
                  'Send Email',
                ),
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

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text('P R O F I L E',
              style: TextStyle(color: Colors.deepPurple.shade300)),
          leading: IconButton(
              color: Colors.deepPurple.shade300,
              icon: Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop()),
        ),
        body: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(16),
                height: height,
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(children: [
                      Container(
                        width: 150,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              NetworkImage(_currentUser.photoURL.toString()),
                        ),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.deepPurple.withOpacity(0.5),
                                width: 5.0)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          child: IconButton(
                            onPressed: _selectImageFromGallery,
                            icon: Icon(
                              Icons.camera_alt_outlined,
                            ),
                            color: Colors.white,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 5,
                                  color: Colors.deepPurple.withOpacity(0.3),
                                )
                              ]),
                        ),
                      ),
                    ]),
                    SizedBox(height: 10),
                    SizedBox(
                        width: width * 0.4,
                        child: Center(
                          child: Text('${_currentUser.displayName}',
                              style: TextStyle(
                                color: Colors.black,
                                //fontSize: 18
                              )),
                        )),
                    SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextFormField(
                                  key: ValueKey('firstname'),
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                      labelText: 'First Name',
                                      border: InputBorder.none,
                                      hintText: 'First name'),
                                  validator: (value) {
                                    if (value!.isNotEmpty &&
                                        !RegExp(r'^[a-z A-Z]+$')
                                            .hasMatch(value)) {
                                      return 'Enter a correct name';
                                    } else
                                      return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextFormField(
                                  key: ValueKey('lastname'),
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      border: InputBorder.none,
                                      hintText: 'Last name'),
                                  validator: (value) {
                                    if (value!.isNotEmpty &&
                                        !RegExp(r'^[a-z A-Z]+$')
                                            .hasMatch(value)) {
                                      return 'Enter a correct name';
                                    } else
                                      return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: TextFormField(
                                  key: ValueKey('email'),
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      border: InputBorder.none,
                                      hintText: 'Email'),
                                  validator: (value) {
                                    if (value!.isNotEmpty &&
                                        !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                            .hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    } else
                                      return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 25.0),
                            child: ElevatedButton(
                                onPressed: () {
                                  _showForgotPasswordDialog(context);
                                },
                                child: Text(
                                  'Reset Password',
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    side: BorderSide(
                                      width: 3.0,
                                      color: Colors.deepPurple.shade300,
                                    ))),
                          ),
                          ElevatedButton(
                              onPressed: _saveChanges,
                              child: Text('Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade300,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              )),
                        ],
                      ),
                    ),
                  ],
                ))));
  }
}
