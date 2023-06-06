import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  bool _isEditing = false;
  late TextEditingController _titleController;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.fence.title);
  }

  @override
  Widget build(BuildContext contextt) {
    void _deleteFenceDialog() {
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: Text("Delete ${_titleController.text}"),
              content: Text(
                  "Are you sure you want to delete ${_titleController.text}? This action is not reversible."),
              actions: [
                CupertinoDialogAction(
                  onPressed: () async {
                    _setLoading(true);
                    Navigator.pop(context); // Close the dialog after deleting

                    await Provider.of<Fences>(context, listen: false)
                        .deleteFence(widget.fence, context);
                    Navigator.pop(contextt); // Close the fence details screen
                    _setLoading(false);
                  },
                  child: Text('Delete Fence'),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No'),
                )
              ],
            );
          });
    }

    void _editFence() {
      setState(() {
        _isEditing = true;
      });
    }

    void _saveFence() async {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fence title cannot be empty.')),
        );
        return;
      }

      _setLoading(true);
      await Provider.of<Fences>(context, listen: false).updateFence(
        widget.fence.id,
        _titleController.text,
      );
      setState(() {
        _isEditing = false;
      });
      _setLoading(false);
    }

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
            centerTitle: true,
            title: _isEditing
                ? TextField(
                    controller: _titleController,
                    autofocus: true,
                    onSubmitted: (_) => _saveFence(),
                    decoration: InputDecoration(
                      hintText: "Enter new title",
                    ),
                  )
                : Text(
                    _titleController.text.toUpperCase(),
                    style: TextStyle(color: Colors.deepPurple),
                  ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              color: Colors.deepPurple.shade300,
              icon: Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (_isEditing)
                IconButton(
                  onPressed: _saveFence,
                  icon: Icon(Icons.save),
                ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  child: IconButton(
                    onPressed: _isEditing ? _saveFence : _editFence,
                    icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
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
            Container(
              child: Image.network(widget.fence.imageUrl, fit: BoxFit.cover),
            )
          ],
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
