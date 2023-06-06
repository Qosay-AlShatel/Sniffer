import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../screens/edit_pet_details.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../providers/pets.dart';
import '../providers/fences.dart';

class PetDetails extends StatefulWidget {
  final String petId;
  const PetDetails({Key? key, required this.petId}) : super(key: key);

  @override
  State<PetDetails> createState() => _PetDetailsState();
}

class _PetDetailsState extends State<PetDetails> {
  bool _isDeleted = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      fetchFences();
    });
  }

  void fetchFences() async {
    await Provider.of<Fences>(context, listen: false).fetchAndSetFences();

    setState(() {
      _isLoading = false;
    });
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext contextt) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_isDeleted) {
      return Center(child: CircularProgressIndicator());
    }

    final pet = Provider.of<Pets>(context, listen: true).findById(widget.petId);
    final name = pet!.name;
    final imageUrl = pet.imageUrl;
    final age = pet.age;
    final description = pet.description;

    final fenceProvider = Provider.of<Fences>(context);
    final fence = fenceProvider.findById(pet.fenceId);
    String fenceTitle = fence!.title;

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    void _deleteDialog() {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text("Delete ${name}"),
            content: Text(
                "Are you sure you want to delete ${name}? This action is not reversible."),
            actions: [
              CupertinoDialogAction(
                onPressed: () async {
                  _setLoading(true);
                  Navigator.pop(context);

                  await Provider.of<Pets>(context, listen: false)
                      .deletePet(widget.petId, context);
                  _isDeleted = true;
                  Navigator.pop(contextt);
                  _setLoading(false);
                },
                child: Text('Delete Pet'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text('No'),
              )
            ],
          );
        },
      );
    }

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Text(
              name.toUpperCase(),
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
                        builder: (context) => EditPetProfile(pet: pet))),
                icon: Icon(Icons.edit),
                color: Colors.deepPurple.shade300,
              ),
            ]),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.topCenter,
              child: Positioned(
                top: 10,
                // left: width * 0.25,

                child: SizedBox(
                  height: height * 0.50,
                  width: width * 0.65,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Positioned(
            //   child: Container(
            //     width: width,
            //     height: height,
            //     padding: const EdgeInsets.all(20),
            //     child: Stack(
            //       children: [
            //         Positioned(
            //             top: 100,
            //             right: 0,
            //             child: SizedBox(
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   PetFeature(
            //                     widget: widget,
            //                     feature: 'Name',
            //                     text: name,
            //                   ),
            //                   PetFeature(
            //                     widget: widget,
            //                     feature: 'Age',
            //                     text: age.toString() + ' years old',
            //                   ),
            //                   PetFeature(
            //                     widget: widget,
            //                     feature: 'Fence',
            //                     text: fenceTitle,
            //                   ),
            //                 ],
            //               ),
            //             )),
            //       ],
            //     ),
            //   ),
            // ),
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
                  ),
                ),
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
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 30.0,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              age.toString() + ' years old',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Expanded(
                      child: Text(
                        description,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                            height: 1.5, fontSize: 18, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            )
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
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white)),
                  onPressed: _deleteDialog,
                  icon: Icon(Icons.delete_forever_outlined),
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
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: AlertDialog(
                              content: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.65,
                                width: double.maxFinite,
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          fenceTitle.toUpperCase(),
                                          style: TextStyle(
                                              color: Colors.deepPurple),
                                          textAlign: TextAlign.center,
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      color: Colors.deepPurple,
                                      thickness: 2,
                                    ),
                                    Expanded(
                                      child: Container(
                                        child: Image.network(
                                          fence.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('View Fence'),
                        Icon(
                          Icons.maps_home_work_sharp,
                          size: 20,
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.deepPurple.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: height * 0.02, horizontal: width * 0.05),
                    ),
                  ),
                ),
              )
            ],
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
