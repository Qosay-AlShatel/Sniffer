import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../providers/trackers.dart';
import '../widgets/trackers_list.dart';
import '../widgets/new_pet_form.dart';
import '../widgets/new_tracker_form.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/pets_grid.dart';
import '../widgets/fences_grid.dart';
import '../widgets/new_fence_form.dart';
import '../widgets/map_page.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/homeScreen';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final refreshNotifier = ValueNotifier<bool>(false);

  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;

  FloatingActionButton? _getFloatingActionButton() {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => NewTrackerForm()),
          );
        },
        child: Icon(Icons.add),
      );
    } else if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewPetForm(
                onPetAdded: () {
                  refreshNotifier.value = !refreshNotifier.value;
                },
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      );
    } else if (_selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewFenceForm(),
            ),
          );
        },
        child: Icon(Icons.add),
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    final List<Widget> _pages = [
      TrackersList(),
      PetsGrid(addRefreshNotifier: refreshNotifier),
      FencesGrid(),
      MapPage(),
    ];

    return Scaffold(
      //backgroundColor: Color.fromRGBO(192, 192, 192, 1.0),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SafeArea(
              child: Container(
                padding: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                    color: Colors.white, //Color.fromRGBO(192, 192, 192, 1.0),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    )),
                height: height * 0.08,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      iconSize: height * 0.04,
                      color: Colors.black,
                      icon: Icon(Icons.logout),
                      onPressed: () {
                        Provider.of<Trackers>(context, listen: false)
                            .cancelSubscriptions();
                        FirebaseAuth.instance.signOut();
                      },
                    ),
                    Container(
                      height: height * .25,
                      width: width * 0.25,
                      child: Image.asset('assets/images/1.png'),
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
              ),
            ),
            Expanded(
              child:
                  Container(color: Colors.white, child: _pages[_selectedIndex]),
            ),
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
              setState(
                () {
                  _selectedIndex = index;
                },
              );
            },
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: Icons.gps_fixed, text: 'Trackers'),
              GButton(icon: Icons.pets, text: 'Pets'),
              GButton(icon: Icons.place, text: 'Fences'),
              GButton(icon: Icons.map, text: 'Maps'),
            ],
          ),
        ),
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }
}
