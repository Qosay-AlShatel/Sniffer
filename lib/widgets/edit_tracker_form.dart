import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../providers/pets.dart';
import '../models/tracker.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final userPets = Provider.of<Pets>(context).pets;
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Tracker'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              initialValue: widget.tracker.id,
              decoration: InputDecoration(labelText: 'Tracker Id'),
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
            Consumer<Trackers>(
              builder: (ctx, trackersProvider, _) => ElevatedButton(
                child: Text('Submit'),
                onPressed: () => _submitForm(trackersProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
