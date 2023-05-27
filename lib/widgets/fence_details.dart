import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/fence.dart';
import '../providers/fences.dart';

class FenceDetails extends StatefulWidget {
  final Fence fence;
  const FenceDetails({Key? key, required this.fence}) : super(key: key);

  @override
  State<FenceDetails> createState() => _FenceDetailsState();
}

class _FenceDetailsState extends State<FenceDetails> {
  late final List<LatLng> _coordinates;
  Set<Polygon> _polygons = HashSet<Polygon>();

  @override
  void initState() {
    super.initState();
    _coordinates = widget.fence.coordinates;
    _fencePolygon();
  }

  void _fencePolygon() {
    final polygonId = PolygonId('fence_polygon');
    final polygon = Polygon(
      polygonId: polygonId,
      points: _coordinates,
      strokeWidth: 2,
      strokeColor: Colors.deepPurple.withOpacity(0.5),
      fillColor: Colors.deepPurple.withOpacity(0.2),
    );
    setState(() {
      _polygons.add(polygon);
    });
  }

  @override
  Widget build(BuildContext context) {
    void _deleteFenceDialog() {
      showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text("Delete ${widget.fence.title}"),
              content: Text(
                  "Are you sure you want to delete ${widget.fence.title}? This action is not reversible."),
              actions: [
                MaterialButton(
                  onPressed: () async {
                    await Provider.of<Fences>(context, listen: false)
                        .deleteFence(widget.fence, context);
                    Navigator.pop(context); // Close the dialog after deleting
                  },
                  child: Text('Delete Fence'),
                ),
                MaterialButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No'),
                )
              ],
            );
          });
    }

    return Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: Text(
              widget.fence.title.toUpperCase(),
              style: TextStyle(color: Colors.deepPurple),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
                color: Colors.deepPurple.shade300,
                icon: Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop()),
            actions: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  child: IconButton(
                    onPressed: _deleteFenceDialog,
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
              ),
            ]),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _coordinates.first,
                zoom: 17,
              ),
              polygons: _polygons,
            ),
          ],
        ));
  }
}
