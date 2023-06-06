import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsHelper {

   static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
     var androidSettings = new AndroidInitializationSettings('mipmap/ic_launcher');
     var iOSSettings =new DarwinInitializationSettings();
     var initializeSettings = new InitializationSettings(android: androidSettings, iOS: iOSSettings);
     flutterLocalNotificationsPlugin.initialize(initializeSettings);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage listeningggg");
      showNotification(title: message.notification?.title, body: message.notification?.body, fln: flutterLocalNotificationsPlugin);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {

    });
   }

   static Future showNotification({var id=0, required String? title, required String? body, var paylad, required FlutterLocalNotificationsPlugin fln}) async {
     AndroidNotificationDetails androidNotificationDetails = new AndroidNotificationDetails(
       'geofence_alerts1',
       'geofence_alerts',
       playSound: true,
       importance: Importance.max,
       priority: Priority.high
     );

     var notif = NotificationDetails(android: androidNotificationDetails, iOS: DarwinNotificationDetails());
     await fln.show(0, title, body, notif);
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



}
