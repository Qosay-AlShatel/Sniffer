import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/fences.dart';
import '../providers/pets.dart';
import '../models/fence.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';

class EditPetProfile extends StatefulWidget {
  final Pet pet;
  const EditPetProfile({Key? key, required this.pet}) : super(key: key);

  @override
  State<EditPetProfile> createState() => _EditPetProfileState();
}

class _EditPetProfileState extends State<EditPetProfile> {
  String? _selectedFenceId;
  List<Fence> fences = [];

  bool _isLoading = false;
  bool _isUploadingImage = false;

  void _setIsUploadingImage(bool value) {
    setState(() {
      _isUploadingImage = value;
    });
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController; //= TextEditingController();
  late TextEditingController _ageController; // = TextEditingController();
  late TextEditingController _descController; // = TextEditingController();

  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<Fences>(context, listen: false).fetchAndSetFences();
      fences = Provider.of<Fences>(context, listen: false).fences;

      // If the current pet does not have a fence, set _selectedFenceId to null.
      _selectedFenceId = widget.pet.fenceId;

      final initialName = widget.pet.name;
      final initialAge = widget.pet.age.toString();
      final initialDesc = widget.pet.description;

      _nameController = TextEditingController(text: initialName);
      _ageController = TextEditingController(text: initialAge);
      _descController = TextEditingController(text: initialDesc);

      setState(() {
        isInitialized = true;
      });
    });
  }

  Future<void> _selectImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final pickedImageFile = await _picker.pickImage(
      imageQuality: 100,
      // maxWidth: 150,
      source: ImageSource.camera,
    );

    if (pickedImageFile != null) {
      File pickedImage = File(pickedImageFile.path);
      await Provider.of<Pets>(context, listen: false)
          .deleteImage(widget.pet.imageUrl);
      _setIsUploadingImage(true);
      final newImageUrl = await Provider.of<Pets>(context, listen: false)
          .uploadImage(pickedImage);
      _setIsUploadingImage(false);
      setState(() {
        widget.pet.imageUrl = newImageUrl;
      });
    }
  }

  Future<void> _selectImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final pickedImageFile = await _picker.pickImage(
      imageQuality: 100,
      // maxWidth: 150,
      source: ImageSource.gallery,
    );

    if (pickedImageFile != null) {
      File pickedImage = File(pickedImageFile.path);
      await Provider.of<Pets>(context, listen: false)
          .deleteImage(widget.pet.imageUrl);
      _setIsUploadingImage(true);
      final newImageUrl = await Provider.of<Pets>(context, listen: false)
          .uploadImage(pickedImage);
      _setIsUploadingImage(false);
      setState(() {
        widget.pet.imageUrl = newImageUrl;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _setLoading(true);
      try {
        final name = _nameController.text.trim();
        final age = int.tryParse(_ageController.text.trim());
        final desc = _descController.text.trim();
        final ownerId = widget.pet.ownerId;
        final fenceId = _selectedFenceId;
        if (name.isNotEmpty && age != null && desc.isNotEmpty) {
          await Provider.of<Pets>(context, listen: false).updatePet(
              widget.pet.id,
              name,
              age,
              desc,
              widget.pet.imageUrl,
              ownerId,
              fenceId!);

          if (fenceId.isEmpty) {
            try {
              await FirebaseMessaging.instance
                  .unsubscribeFromTopic('geofence_alerts');
              print('Unsubscribed from geofence_alerts topic');
            } catch (e) {
              print('Failed to unsubscribe from geofence_alerts topic: $e');
            }
          } else {
            FirebaseMessaging.instance
                .subscribeToTopic('geofence_alerts')
                .then((value) {
              print('Subscribed to geofence_alerts topic!');
            }).catchError((error) {
              print('Failed to subscribe to geofence_alerts topic: $error');
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pet profile updated successfully!'),
            ),
          );
          _setLoading(false);
          Navigator.of(context).pop();
        }
      } catch (e) {
        _setLoading(false);
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
    final fences = Provider.of<Fences>(context, listen: false).fences;

    return Stack(
      children: [
        isInitialized
            ? Scaffold(
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
                                  NetworkImage(widget.pet.imageUrl),
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
                                  Icons.photo_library,
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
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              child: IconButton(
                                onPressed: _selectImageFromCamera,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20.0),
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 20.0),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedFenceId == ""
                                          ? null
                                          : _selectedFenceId,
                                      items: [
                                        ...fences.map<DropdownMenuItem<String>>(
                                          (Fence fence) {
                                            return DropdownMenuItem<String>(
                                              value: fence.id,
                                              child: Text(fence.title),
                                            );
                                          },
                                        ).toList(),
                                        if (_selectedFenceId != "")
                                          DropdownMenuItem<String>(
                                            value:
                                                "", // Value representing no fence
                                            child: Text("No fence"),
                                          ),
                                      ],
                                      hint: Text("Select a fence"),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedFenceId = newValue!;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.0),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              SizedBox(height: 16.0),
                              _isUploadingImage
                                  ? CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _saveChanges,
                                      child: Text('Save Changes'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.deepPurple.shade300,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Center(
                child: CircularProgressIndicator(),
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
