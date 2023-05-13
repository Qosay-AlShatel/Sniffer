import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../providers/pet.dart';

class EditPetProfile extends StatefulWidget {
  final Pet pet;
  const EditPetProfile({Key? key, required this.pet}) : super(key: key);

  @override
  State<EditPetProfile> createState() => _EditPetProfileState();
}

class _EditPetProfileState extends State<EditPetProfile> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController; //= TextEditingController();
  late TextEditingController _ageController;// = TextEditingController();
  late TextEditingController _descController;// = TextEditingController();

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

  Future<void> _deletePet() async{
    try{
    await FirebaseFirestore.instance
        .collection('pets')
        .doc(widget.pet.id).delete();
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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        final name = _nameController.text.trim();
        final age = _ageController.text.trim();
        final desc = _descController.text.trim();

        if(name.isNotEmpty ) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'name': name});
        }

        if(age.isNotEmpty ) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'age': int.tryParse(age)});
        }

        if(desc.isNotEmpty ) {
          FirebaseFirestore.instance
              .collection('pets')
              .doc(widget.pet.id)
              .update({'description': desc});
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
              content: Text("Are you sure you want to delete ${widget.pet.name}? This action is not reversible."),
              actions: [
                MaterialButton(
                  onPressed: _deletePet,
                  child: Text('Delete pet'),
                ),
                MaterialButton(
                  onPressed: ()=> Navigator.pop(context),
                  child: Text('No'),
                )
              ],
            );
          }
      );
    }
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text('P R O F I L E', style: TextStyle(color: Colors.deepPurple.shade300)),
          leading: IconButton(
              color: Colors.deepPurple.shade300,
              icon: Icon(Icons.close_rounded),
              onPressed: ()=>Navigator.of(context).pop()),
        ),
        body: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(16),
                height: height,
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.transparent,
                        child: Image.network(widget.pet.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.deepPurple.withOpacity(0.5),
                              width: 5.0
                          )
                      ),
                    ),
                    SizedBox( height: 10),
                    SizedBox(
                        width: width*0.4,
                        child:
                        Center(
                          child: Text('${widget.pet.name}',
                              style: TextStyle(
                                color: Colors.black,
                                //fontSize: 18
                              )),
                        )
                    ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                                      border: InputBorder.none, hintText: 'Description'),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              )
                          ),
                          Container(
                            width: width*0.3,
                            height: 36.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              border: Border.all(
                                color: Colors.deepPurple.shade300
                              )

                            ),
                            child: ElevatedButton(
                                onPressed: _deleteDialog,
                                child: Text('Delete pet',
                                style: TextStyle(color: Colors.deepPurple[300])
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
            )
        )
    );
  }
}
