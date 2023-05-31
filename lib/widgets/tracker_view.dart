import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pets.dart';
import '../providers/trackers.dart';
import '../models/tracker.dart';
import './edit_tracker_form.dart';

class TrackerView extends StatelessWidget {
  final Tracker tracker;

  const TrackerView({Key? key, required this.tracker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final trackersProvider = Provider.of<Trackers>(context, listen: false);
    final petsProvider = Provider.of<Pets>(context);
    final pet = petsProvider.findById(tracker.petId);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(pet?.imageUrl ?? ""),
        ),
        title: Text(
          tracker.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text('Tracking ${pet?.name ?? ""}'), // Displaying the pet name
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                // Receive the updated tracker from EditTrackerForm
                final updatedTracker = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ChangeNotifierProvider.value(
                      value:
                          trackersProvider, // Using existing provider instance instead of creating new one
                      child: EditTrackerForm(tracker: tracker),
                    ),
                  ),
                );
                // If there is an updated tracker, update it locally
                if (updatedTracker != null) {
                  trackersProvider.updateLocalTracker(updatedTracker);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Confirm Deletion"),
                      content:
                          Text("Are you sure you want to delete this tracker?"),
                      actions: <Widget>[
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text("Delete"),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await trackersProvider.removeTracker(tracker.id);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
