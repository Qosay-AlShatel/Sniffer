import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pets.dart';
import '../models/tracker.dart';

class TrackerView extends StatelessWidget {
  final Tracker tracker;

  const TrackerView({Key? key, required this.tracker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final petsProvider = Provider.of<Pets>(context);
    final pet = petsProvider.findById(tracker.petId);

    if (pet == null) {
      return Center(child: Text('Pet not found'));
    } else {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(pet.imageUrl),
          ),
          title: Text(
            tracker.title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Tracking ${pet.name}'), // Displaying the pet name
          trailing: Text(
            'Location: ${tracker.latitude}, ${tracker.longitude}', // Displaying the tracker's location
          ),
        ),
      );
    }
  }
}
