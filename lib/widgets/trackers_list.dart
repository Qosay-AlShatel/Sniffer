import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../providers/pets.dart';
import './tracker_view.dart';

class TrackersList extends StatefulWidget {
  const TrackersList({Key? key}) : super(key: key);

  @override
  _TrackersListState createState() => _TrackersListState();
}

class _TrackersListState extends State<TrackersList> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('TrackersList: initState');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // Load Pets data
      await Provider.of<Pets>(context, listen: false).fetchPets();
      // Load Trackers data
      await Provider.of<Trackers>(context, listen: false).fetchAndSetTrackers();
    } catch (error) {
      print('TrackersList: error loading data: $error');
    }
    setState(() {
      _isLoading = false;
    });
    print('TrackersList: data loaded');
  }

  @override
  Widget build(BuildContext context) {
    final trackersData = Provider.of<Trackers>(context);
    final trackers = trackersData.trackers;
    print('TrackersList: build');
    return Consumer<Trackers>(
      builder: (ctx, trackersData, child) {
        if (_isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.deepPurple[300],
            ),
          );
        } else if (trackersData.trackers.isEmpty) {
          return Center(
            child: Text('No trackers found.'),
          );
        } else {
          print('TrackersList: rendering list');
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: trackersData.trackers.length,
            itemBuilder: (ctx, i) {
              print('TrackersList: rendering tracker ${i + 1}');
              return GestureDetector(
                onTap: () {
                  if (trackers[i].isDisabled)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tracker ${trackers[i].title} is disabled!\n'
                          'Please add a pet to enable it.',
                          textAlign: TextAlign.center,
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  else
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tracker ${trackers[i].title} tapped!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                },
                child: TrackerView(tracker: trackers[i]),
              );
            },
          );
        }
      },
    );
  }
}
