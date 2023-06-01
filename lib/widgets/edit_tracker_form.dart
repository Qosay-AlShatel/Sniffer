import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../providers/pets.dart';
import '../models/tracker.dart';

//TODO: fix delete dialog
class EditTrackerForm extends StatefulWidget {
  final Tracker tracker;

  EditTrackerForm({Key? key, required this.tracker}) : super(key: key);

  @override
  _EditTrackerFormState createState() => _EditTrackerFormState();
}

class _EditTrackerFormState extends State<EditTrackerForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _titleController = TextEditingController();
  String _selectedPet = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.tracker.title;
    _selectedPet = widget.tracker.petId;
  }

  void _submitForm(Trackers trackersProvider) {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please check your entries')),
      );
      return;
    }
    _formKey.currentState?.save();

    // Update tracker details
    Tracker updatedTracker = Tracker(
      id: widget.tracker.id,
      title: _titleController.text,
      petId: _selectedPet,
      ownerId: widget.tracker.ownerId,
      longitude: widget.tracker.longitude,
      latitude: widget.tracker.latitude,
    );

    trackersProvider.updateTrackerDetails(updatedTracker, context);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final userPets = Provider.of<Pets>(context).pets;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text('Edit Tracker'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
        key: _formKey,
              child: Column(
            children: [
              TextFormField(
                initialValue: widget.tracker.id,
                decoration: InputDecoration(labelText: 'Tracker Id',),
                enabled: false,
              ),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              DropdownButtonFormField(
                value: _selectedPet,
                items: userPets
                    .map((pet) => DropdownMenuItem(
                          child: Text(pet.name),
                          value: pet.id,
                        ))
                    .toList(),
                onChanged: (String? petId) {
                  _selectedPet = petId!;
                  print('Selected pet id: $_selectedPet');
                },
                decoration: InputDecoration(labelText: 'Tracked Pet'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please choose a pet';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Longitude'),
                initialValue: widget.tracker.longitude.toString(),
                enabled: false,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Latitude'),
                initialValue: widget.tracker.latitude.toString(),
                enabled: false,
              ),
              SizedBox(height: 16),
              Consumer<Trackers>(
                builder: (ctx, trackersProvider, _) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.25),
                  child: ElevatedButton(
                    onPressed: () => _submitForm(trackersProvider),
                    child:
                        Text('Save Changes'),
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
              ),
            ],
        ),
      ),
          ),
    ]));
  }
}
