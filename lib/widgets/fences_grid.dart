import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fences.dart';
import './fence_view.dart';

class FencesGrid extends StatefulWidget {
  const FencesGrid({Key? key}) : super(key: key);

  @override
  _FencesGridState createState() => _FencesGridState();
}

class _FencesGridState extends State<FencesGrid> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    Provider.of<Fences>(context, listen: false).fetchAndSetFences().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final fencesData = Provider.of<Fences>(context);
    final fences = fencesData.fences;

    if (fences.isEmpty) {
      return Center(
        child: Text('No fences added yet.'),
      );
    }

    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: fences.length,
            itemBuilder: (ctx, i) => FenceView(fence: fences[i]),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
          );
  }
}
