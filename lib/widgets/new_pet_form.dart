import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewPetForm extends StatefulWidget {
  final VoidCallback onPetAdded;

  NewPetForm({required this.onPetAdded});

  @override
  _NewPetFormState createState() => _NewPetFormState();
}

class _NewPetFormState extends State<NewPetForm> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  File? _pickedImage;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _name;
  int? _age;
  String? _description;

  Future<String> _uploadImage(File imageFile) async {
    String fileName = 'pets/${DateTime.now().toIso8601String()}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);

    final UploadTask uploadTask = storageRef.putFile(imageFile);

    await uploadTask.whenComplete(() {});
    final String downloadUrl = await storageRef.getDownloadURL();

    return downloadUrl;
  }

  Future<void> _addPet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in before adding a pet')),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _pickedImage != null) {
      _formKey.currentState!.save();

      _setLoading(true);

      String imageUrl;
      try {
        imageUrl = await _uploadImage(_pickedImage!);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $error')),
        );
        _setLoading(false);
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('pets').add({
          'name': _name,
          'age': _age,
          'description': _description,
          'imageUrl': imageUrl,
          'ownerId': user.uid,
        });

        _setLoading(false);
        Navigator.of(context).pop();
        widget.onPetAdded();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving pet: $error')),
        );
        _setLoading(false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields and take a photo')),
      );
    }
  }

  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access camera is required.')),
      );
      return;
    }

    final ImagePicker _picker = ImagePicker();
    final pickedImageFile = await _picker.pickImage(
      imageQuality: 50,
      maxWidth: 150,
      source: ImageSource.camera,
    );

    setState(() {
      if (pickedImageFile != null) {
        _pickedImage = File(pickedImageFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('New Pet'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Center(
                    child: _pickedImage == null
                        ? Text('No image selected')
                        : Image.file(_pickedImage!),
                  ),
                  ElevatedButton(
                    onPressed: _takePhoto,
                    child: Text('Take a Photo'),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Pet Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a pet name';
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Pet Age'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the pet age';
                      }
                      return null;
                    },
                    onSaved: (value) => _age = int.tryParse(value!),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Description'),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                    onSaved: (value) => _description = value,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addPet,
                    child: Text('Add Pet'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
