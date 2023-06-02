import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './pet_details.dart';
import '../providers/pets.dart';
import './pet_view.dart';

class PetsGrid extends StatefulWidget {
  const PetsGrid({Key? key}) : super(key: key);

  @override
  _PetsGridState createState() => _PetsGridState();
}

class _PetsGridState extends State<PetsGrid> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    Provider.of<Pets>(context, listen: false).fetchPets().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsData = Provider.of<Pets>(context);
    final pets = petsData.pets;

    if (pets.isEmpty) {
      return Center(
        child: Text('No pets added yet.'),
      );
    }

    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
            color: Colors.deepPurple[300],
          ))
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: pets.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PetDetails(pet: pets[i]),
                ),
              ),
              child: PetView(index: i),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
          );
  }
}
