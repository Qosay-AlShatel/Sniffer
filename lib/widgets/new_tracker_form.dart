import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../providers/pets.dart';
import '../models/tracker.dart';

class NewTrackerForm extends StatefulWidget {
  @override
  _NewTrackerFormState createState() => _NewTrackerFormState();
}

class _NewTrackerFormState extends State<NewTrackerForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _trackerIdController = TextEditingController();
  final _titleController = TextEditingController();
  Tracker _newTracker = Tracker(
    id: '',
    title: '',
    petId: '',
    ownerId: '',
    longitude: 0.0,
    latitude: 0.0,
  );
  String _selectedPet = '';
  bool _isValidTrackerId = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petsData = Provider.of<Pets>(context, listen: false).pets;
      if (petsData.isNotEmpty) {
        setState(() {
          _selectedPet = petsData[0].id;
        });
      } else {
        print("No pets found");
        // Handle this case as you see fit
      }
    });
  }

  Future<void> _checkTrackerId() async {
    if (_trackerIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a tracker id')),
      );
      return;
    }
    final isValid = await Provider.of<Trackers>(context, listen: false)
        .checkTrackerId(_trackerIdController.text);
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid tracker id')),
      );
      return;
    }

    _newTracker = await Provider.of<Trackers>(context, listen: false)
        .fetchTrackerDetails(_trackerIdController.text);

    setState(() {
      _isValidTrackerId = true;
    });
  }

  void _submitForm() {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please check your entries')),
      );
      return;
    }
    _formKey.currentState?.save();

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    _newTracker.title = _titleController.text;
    _newTracker.petId = _selectedPet;
    _newTracker.ownerId = user.uid;

    Provider.of<Trackers>(context, listen: false)
        .updateTrackerDetails(_newTracker, context);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<Pets>(context).fetchPets();
    final userPets = Provider.of<Pets>(context).pets;
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Tracker'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _trackerIdController,
              decoration: InputDecoration(labelText: 'Tracker Id'),
            ),
            ElevatedButton(
              child: Text('Check Id'),
              onPressed: _checkTrackerId,
            ),
            if (_isValidTrackerId) ...[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              DropdownButtonFormField(
                value: userPets.isNotEmpty ? userPets.first.id : null,
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
                initialValue: _newTracker.longitude.toString(),
                enabled: false,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Latitude'),
                initialValue: _newTracker.latitude.toString(),
                enabled: false,
              ),
              ElevatedButton(
                child: Text('Submit'),
                onPressed: () {
                  _submitForm();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
