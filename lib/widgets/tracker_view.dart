import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pets.dart';
import '../providers/trackers.dart';
import '../models/tracker.dart';
import './edit_tracker_form.dart';

class TrackerView extends StatelessWidget {
  final Tracker tracker;

  const TrackerView({Key? key, required this.tracker}) : super(key: key);

  void _showPetsDialog(BuildContext context) {
    final petsProvider = Provider.of<Pets>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Choose a pet'),
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black),
          ),
          height: MediaQuery.of(context).size.height * 0.15,
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: petsProvider.pets.length,
            itemBuilder: (ctx, i) => ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(petsProvider.pets[i].imageUrl),
              ),
              title: Text(petsProvider.pets[i].name),
              onTap: () {
                Navigator.of(context).pop();
                tracker.petId = petsProvider.pets[i].id;
                tracker.isDisabled = false;
                Provider.of<Trackers>(context, listen: false)
                    .updateTrackerDetails(tracker, context);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackersProvider = Provider.of<Trackers>(context, listen: false);
    final petsProvider = Provider.of<Pets>(context);
    final pet = petsProvider.findById(tracker.petId);

    return Card(
      child: ListTile(
        enabled: !tracker.isDisabled,
        leading: CircleAvatar(
          backgroundImage: NetworkImage(pet?.imageUrl ?? ""),
        ),
        title: Text(
          tracker.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: tracker.isDisabled
            ? Text('No pet attached')
            : Text('Tracking ${pet?.name ?? ""}'), // Displaying the pet name
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            !tracker.isDisabled
                ? IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ChangeNotifierProvider.value(
                            value: trackersProvider,
                            child: EditTrackerForm(tracker: tracker),
                          ),
                        ),
                      );
                    },
                  )
                : IconButton(
                    icon: Icon(Icons.pets),
                    onPressed: () => _showPetsDialog(context)),
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
