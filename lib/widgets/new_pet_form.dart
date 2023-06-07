import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/pets.dart';
import '../models/pet.dart';
import '../providers/fences.dart';
import '../models/fence.dart';

class NewPetForm extends StatefulWidget {
  final VoidCallback onPetAdded;

  NewPetForm({required this.onPetAdded});

  @override
  _NewPetFormState createState() => _NewPetFormState();
}

class _NewPetFormState extends State<NewPetForm> {
  bool _isLoading = false;

  String? _fenceId;
  List<Fence>? _fences;

  @override
  void initState() {
    super.initState();
    _loadFences();
  }

  Future<void> _loadFences() async {
    await Provider.of<Fences>(context, listen: false).fetchAndSetFences();
    setState(() {
      _fences = Provider.of<Fences>(context, listen: false).fences;
    });
  }

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

  Future<void> _selectImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final pickedImageFile = await _picker.pickImage(
      imageQuality: 100,
      // maxWidth: 150,
      source: ImageSource.gallery,
    );

    setState(() {
      if (pickedImageFile != null) {
        _pickedImage = File(pickedImageFile.path);
      }
    });
  }

  Future<void> _addPet() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_formKey.currentState!.validate() && _pickedImage != null) {
      _formKey.currentState!.save();

      _setLoading(true);

      String imageUrl;
      try {
        imageUrl = await Provider.of<Pets>(context, listen: false)
            .uploadImage(_pickedImage!);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $error')),
        );
        _setLoading(false);
        return;
      }

      try {
        // Create a new Pet object
        Pet newPet = Pet(
          id: '',
          name: _name!,
          age: _age!,
          description: _description!,
          imageUrl: imageUrl,
          ownerId: user!.uid,
          fenceId: _fenceId ?? '',
        );

        // Use the provider to add the pet
        await Provider.of<Pets>(context, listen: false).addPet(newPet);

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
        SnackBar(content: Text('Please fill in all fields and upload a photo')),
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
      imageQuality: 100,
      // maxWidth: 150,
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
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            title: Text('New Pet'),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Center(
                    child: _pickedImage == null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                                width: width * 0.2,
                                height: height * 0.1,
                                color: Colors.grey[200],
                                child: IconButton(
                                  icon: Icon(Icons.camera_alt_outlined),
                                  onPressed: _takePhoto,
                                )),
                          )
                        : Image.file(_pickedImage!),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100)),
                            padding: EdgeInsets.symmetric(
                                vertical: height * 0.02,
                                horizontal: width * 0.04),
                            elevation: 0),
                        onPressed: _selectImageFromGallery,
                        child: Text('Upload photo from gallery'),
                      ),
                    ],
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.25),
                    child: ElevatedButton(
                      onPressed: _addPet,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Add Pet'),
                          Icon(
                            Icons.pets_rounded,
                            size: 15,
                          )
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.deepPurple[100],
                        foregroundColor: Colors.deepPurple[500],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: height * 0.02, horizontal: width * 0.05),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Fence'),
                    value: _fenceId,
                    items: _fences?.map((Fence fence) {
                      return DropdownMenuItem<String>(
                        value: fence.id,
                        child: Text(fence.title),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _fenceId = newValue;
                      });
                    },
                    // Allowing for the value to be null
                    validator: (value) => null,
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
