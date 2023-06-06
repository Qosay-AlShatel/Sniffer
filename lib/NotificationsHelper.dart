import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsHelper {

   static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  //   var androidSettings = new AndroidInitializationSettings('assets/images/2.png');
  //   //var iOSSettings =new IOSInitializationSettings
  //   var initializeSettings = new InitializationSettings(android: androidSettings);
  //   flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true
    );

    FirebaseMessaging.onMessage.listen((Remote) {

    });
   }

  void subscribeToGeofenceAlerts(String tracker, BuildContext context) {
    FirebaseMessaging.instance.subscribeToTopic(tracker).then((value) {
      print('Subscribed to $tracker topic!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enabled $tracker notifications'),
        ),
      );
    }).catchError((error) {
      print('Failed to subscribe to $tracker topic: $error');
    });
  }

  Future<void> unsubscribeFromGeofence(String tracker, BuildContext context) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(tracker);
      print('Unsubscribed from $tracker topic');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disabled $tracker notifications'),
        ),
      );
    } catch (e) {
      print('Failed to unsubscribe from $tracker topic: $e');
    }
  }

  void onMessageOpened() {
    //Reroute on notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened...");
      print("onAppOpened: ${message.notification?.title}/${message.notification?.body}");
      try{
        if(message.notification?.titleLocKey != null){
          print("routing to map page");
        }
      }catch (e){
        print("ERROR: "+e.toString());
      }
    });
  }


}
