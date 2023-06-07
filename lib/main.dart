import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './providers/pets.dart';
import './screens/home_screen.dart';
import './screens/auth_screen.dart';
import './screens/onBoarding_screens/onBoarding_screens.dart';
import 'NotificationsHelper.dart';
import 'providers/fences.dart';
import 'providers/trackers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    final RemoteMessage? remoteMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    await NotificationsHelper.initialize(flutterLocalNotificationsPlugin);
  } catch (e) {}
  // Set up the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showOnboarding = true;
  bool _isLoading = true;

  void setShowOnboarding(bool show) {
    setState(() {
      _showOnboarding = show;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    NotificationsHelper.initialize(flutterLocalNotificationsPlugin);
  }

  Future<void> _checkOnboardingStatus() async {
    print('Checking onboarding status...');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (hasSeenOnboarding) {
      setState(() {
        _showOnboarding = false;
      });
    }
    setState(() {
      _isLoading = false;
      print('Onboarding status checked. _isLoading: $_isLoading');
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Trackers()),
        ChangeNotifierProvider(create: (ctx) => Fences()),
        Provider<FirebaseAuth>.value(value: FirebaseAuth.instance),
        ChangeNotifierProxyProvider<FirebaseAuth, Pets>(
          create: (ctx) => Pets(''),
          update: (ctx, auth, previousPets) => Pets(auth.currentUser!.uid),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Sniffer',
        routes: {
          AuthScreen.routeName: (ctx) => AuthScreen(),
          HomeScreen.routeName: (ctx) => HomeScreen(),
          onBoardingScreens.routeName: (ctx) =>
              onBoardingScreens(setShowOnboarding),
        },
        theme: ThemeData(
          buttonTheme: ButtonTheme.of(context).copyWith(
            buttonColor: Colors.deepPurple[300],
            textTheme: ButtonTextTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
              .copyWith(background: Colors.deepPurple)
              .copyWith(secondary: Colors.deepPurple[300]),
        ),
        home: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _showOnboarding
                ? onBoardingScreens(setShowOnboarding)
                : StreamBuilder(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (ctx, userSnapshot) {
                      if (userSnapshot.hasData) {
                        User user = userSnapshot.data as User;

                        // Check if the user's email address is verified
                        if (user.emailVerified) {
                          return HomeScreen();
                        } else {
                          // Show a message or a screen asking the user to verify their email
                          return Scaffold(
                            appBar: AppBar(
                              title: Text('Email Verification'),
                              actions: <Widget>[
                                IconButton(
                                  onPressed: () => navigatorKey.currentState!
                                      .pushNamed(AuthScreen.routeName),
                                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                                )
                              ],
                            ),
                            body: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Please verify your email address.'),
                                  TextButton(
                                    onPressed: () async {
                                      await user.sendEmailVerification();
                                    },
                                    child: Text('Resend Verification Email'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await user.reload(); // Reload user data
                                      user = FirebaseAuth.instance
                                          .currentUser!; // Update user object
                                      setState(
                                          () {}); // Rebuild the widget to update the UI
                                    },
                                    child: Text('Check Verification'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return AuthScreen();
                    },
                  ),
      ),
    );
  }
}
