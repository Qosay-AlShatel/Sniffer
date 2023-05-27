import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pets.dart';

class PetView extends StatelessWidget {
  final int index;

  PetView({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pet = Provider.of<Pets>(context, listen: false).pets[index];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        child: Image.network(
          pet.imageUrl,
          fit: BoxFit.cover,
        ),
        footer: GridTileBar(
          backgroundColor: Colors.deepPurple[200],
          title: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${pet.age} years old',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
