import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sniffer_pettracking_app/screens/edit_pet_details.dart';

import '../providers/pet.dart';

class PetDetails extends StatefulWidget {
  final Pet pet;
  final VoidCallback onPetEditDel;
  const PetDetails({Key? key, required this.pet, required this.onPetEditDel})
      : super(key: key);

  @override
  State<PetDetails> createState() => _PetDetailsState();
}

class _PetDetailsState extends State<PetDetails> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _deletePet() async {
    _setLoading(true);
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
      _setLoading(false);
      Navigator.of(context).pop();
      widget.onPetEditDel();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting pet profile: $e'),
        ),
      );
      _setLoading(false);
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
            return AlertDialog(
              title: Text("Delete ${widget.pet.name}"),
              content: Text(
                  "Are you sure you want to delete ${widget.pet.name}? This action is not reversible."),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deletePet();
                  },
                  child: Text('Delete pet'),
                ),
                MaterialButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No'),
                )
              ],
            );
          });
      setState(() {});
    }

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Text(
              widget.pet.name.toUpperCase(),
              style: TextStyle(color: Colors.deepPurple),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
                color: Colors.deepPurple.shade300,
                icon: Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop()),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditPetProfile(pet: widget.pet))),
                icon: Icon(Icons.edit),
                color: Colors.deepPurple.shade300,
              ),
            ]),
        body: Stack(
          children: [
            Positioned(
                top: 10,
                left: 10,
                child: SizedBox(
                    height: height * 0.50,
                    child: Image.network(
                      widget.pet.imageUrl,
                      fit: BoxFit.cover,
                    ))),
            Positioned(
              child: Container(
                  width: width,
                  height: height,
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Positioned(
                          top: 100,
                          right: 0,
                          child: SizedBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                PetFeature(
                                  widget: widget,
                                  feature: 'Name',
                                  text: widget.pet.name,
                                ),
                                PetFeature(
                                  widget: widget,
                                  feature: 'Age',
                                  text:
                                      widget.pet.age.toString() + ' years old',
                                ),
                              ],
                            ),
                          )),
                    ],
                  )),
            ),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
                  height: height * 0.4,
                  width: width,
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        topLeft: Radius.circular(30),
                      )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pet.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30.0,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(widget.pet.age.toString() + ' years old',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold))
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              height: 40,
                              width: 40,
                              child: IconButton(
                                onPressed: _deleteDialog,
                                icon: Icon(Icons.delete_outline_rounded),
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
                          )
                        ],
                      ),
                      SizedBox(height: 15),
                      Expanded(
                          child: Text(widget.pet.description,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                  height: 1.5,
                                  fontSize: 18,
                                  color: Colors.white70)))
                    ],
                  ),
                ))
          ],
        ),
        floatingActionButton: SizedBox(
            width: width * 0.9,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.maps_home_work_sharp),
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
                SizedBox(height: 20),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 1),
                            blurRadius: 5,
                            color: Colors.deepPurple.withOpacity(0.3),
                          )
                        ]),
                    child: Center(
                      child: Text(
                        widget.pet.name.toUpperCase() + '\'S FENCE',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.90),
                            fontSize: 20.0),
                      ),
                    ),
                  ),
                ))
              ],
            )),
      ),
      if (_isLoading)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ]);
  }
}

/**
 * Pet feature widget for reusability
 */
class PetFeature extends StatelessWidget {
  final String feature;
  final String text;
  const PetFeature(
      {super.key,
      required this.widget,
      required this.feature,
      required this.text});

  final PetDetails widget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature,
          style: TextStyle(
            color: Colors.black.withOpacity(0.8),
          ),
        ),
        Text(text,
            style: TextStyle(
                color: Colors.deepPurple.shade300,
                fontSize: 18,
                fontWeight: FontWeight.bold))
      ],
    );
  }
}
