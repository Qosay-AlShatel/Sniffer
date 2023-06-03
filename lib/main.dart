import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sniffer_pettracking_app/firebase_options.dart';

import './providers/pets.dart';
import './screens/home_screen.dart';
import './screens/auth_screen.dart';
import './screens/onBoarding_screens/onBoarding_screens.dart';
import 'providers/fences.dart';
import 'providers/trackers.dart';
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  print("Handling a background message: ${message.messageId}");
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  /*NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );*/
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  runApp(MyApp());
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
                            appBar: AppBar(title: Text('Email Verification')),
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
