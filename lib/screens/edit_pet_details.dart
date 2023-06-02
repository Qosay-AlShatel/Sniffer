import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';

class EditPetProfile extends StatefulWidget {
  final Pet pet;
  const EditPetProfile({Key? key, required this.pet}) : super(key: key);

  @override
  State<EditPetProfile> createState() => _EditPetProfileState();
}

class _EditPetProfileState extends State<EditPetProfile> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController; //= TextEditingController();
  late TextEditingController _ageController; // = TextEditingController();
  late TextEditingController _descController; // = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialName = widget.pet.name;
    final initialAge = widget.pet.age.toString();
    final initialDesc = widget.pet.description;
    _nameController = TextEditingController(text: initialName);
    _ageController = TextEditingController(text: initialAge);
    _descController = TextEditingController(text: initialDesc);
  }

  Future<void> _deletePet() async {
    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.pet.id)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pet profile deleted successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting pet profile: $e'),
        ),
      );
    }
    setState(() {
      Navigator.of(context).pop();
    });
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
        final name = _nameController.text.trim();
        final age = _ageController.text.trim();
        final desc = _descController.text.trim();

        if (name.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'name': name});
        }

        if (age.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'age': int.tryParse(age)});
        }

        if (desc.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'description': desc});
        }

        if (imageUrl.isNotEmpty) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'imageUrl': imageUrl});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet profile updated successfully!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating pet profile: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    void _deleteDialog() {
      showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text("Delete ${widget.pet.name}"),
              content: Text(
                  "Are you sure you want to delete ${widget.pet.name}? This action is not reversible."),
              actions: [
                MaterialButton(
                  onPressed: _deletePet,
                  child: Text('Delete pet'),
                ),
                MaterialButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No'),
                )
              ],
            );
          });
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
                          backgroundImage: NetworkImage(widget.pet.imageUrl),
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
                          child: Text('${widget.pet.name}',
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
                                  key: ValueKey('name'),
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                      labelText: 'Name',
                                      border: InputBorder.none,
                                      hintText: 'Name'),
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
                                  key: ValueKey('age'),
                                  controller: _ageController,
                                  decoration: InputDecoration(
                                      labelText: 'Age',
                                      border: InputBorder.none,
                                      hintText: 'Age'),
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
                                  key: ValueKey('description'),
                                  controller: _descController,
                                  decoration: InputDecoration(
                                      labelText: 'Description',
                                      border: InputBorder.none,
                                      hintText: 'Description'),
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
                            ),
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: _saveChanges,
                            child: Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ))));
  }
}
