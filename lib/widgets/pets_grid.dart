import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet.dart';
import '../providers/pets.dart';
import './pet_view.dart';

class PetsGrid extends StatefulWidget {
  final ValueNotifier<bool> refreshNotifier;

  PetsGrid({required this.refreshNotifier});

  @override
  State<PetsGrid> createState() => _PetsGridState();
}

class _PetsGridState extends State<PetsGrid> {
  late Future<List<Pet>> _fetchPetsFuture;

  @override
  void initState() {
    super.initState();
    super.initState();
    final petsProvider = Provider.of<Pets>(context, listen: false);
    _fetchPetsFuture = petsProvider.fetchPets();
    widget.refreshNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final petsProvider = Provider.of<Pets>(context, listen: false);
    setState(() {
      _fetchPetsFuture = petsProvider.fetchPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Pet>>(
      future: _fetchPetsFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('An error occurred!'));
        } else if (snapshot.hasData) {
          final pets = snapshot.data!;
          if (pets.isEmpty) {
            return Center(child: Text('No pets found.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: pets.length,
            itemBuilder: (ctx, i) => ChangeNotifierProvider<Pet>.value(
              value: pets[i],
              child: PetView(),
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
          );
        } else {
          return Center(child: Text('No pets found.'));
        }
      },
    );
  }
}
