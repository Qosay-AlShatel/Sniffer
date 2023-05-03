import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../screens/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    final List<Widget> _pages = [
      //YOU CAN REPLACE THE CENTER WIDGETS WITH YOUR CUSTOM WIDGET OR CLASS NAME
      Center(
        child: Text('Home'),
      ),
      Center(
        child: Text('Pets'),
      ),
      Center(
        child: Text('Fences'),
      ),
      Center(
        child: Column(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    iconSize: height * 0.05,
                    color: Colors.black,
                    icon: Icon(Icons.logout),
                    onPressed: () => FirebaseAuth.instance.signOut()),
                Container(
                  height: height * .25,
                  width: width * 0.25,
                  child: Image.asset('assets/images/2.png'),
                ),
                IconButton(
                  icon: Icon(Icons.account_circle_rounded),
                  color: Colors.black,
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => UserProfileScreen()));
                  },
                  iconSize: height * 0.05,
                )
              ],
            ),
            _pages[_selectedIndex],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: GNav(
            backgroundColor: Colors.black,
            gap: 8, // the tab button gap between icon and text
            color: Colors.white, // unselected icon color
            activeColor: Colors.deepPurple[200], // selected icon and text color
            tabBackgroundColor: Colors
                .deepPurple, //TODO: Change background color individually based on page UI
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.pets, text: 'Pets'),
              GButton(icon: Icons.place, text: 'Fences'),
              GButton(icon: Icons.map, text: 'Maps'),
            ],
          ),
        ),
      ),
    );
  }
}
