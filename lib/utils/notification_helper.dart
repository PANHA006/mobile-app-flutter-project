
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; // To access isFirebaseInitialized

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initSystemNotifications() async {
  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
        
    // Send a test notification immediately so the user can verify it works
    showSystemNotification(
      'Welcome to English AI Study App!', 
      'Notifications are fully enabled and working.'
    );
  } catch (e) {
    debugPrint('Failed to initialize local notifications: $e');
  }
}

Future<void> showSystemNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'english_ai_study_app_channel',
    'Study Alerts',
    channelDescription: 'Notifications for study goals and updates',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'Study Alert',
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond,
    title,
    body,
    platformChannelSpecifics,
  );
}

void addAppNotification({
  required String title,
  required String body,
  required String iconName,
  String? uid,
}) {
  try {
    final box = Hive.box('vocabulary_box');
    final List<dynamic> rawList = box.get('notifications_list') ?? [];
    final List<Map<String, dynamic>> list = rawList.map((e) => Map<String, dynamic>.from(e)).toList();

    final newNotif = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'icon': iconName,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'unread': true,
    };

    list.insert(0, newNotif);

    if (list.length > 50) {
      list.removeLast();
    }

    box.put('notifications_list', list);

    // Save to Firestore if user ID is available and Firebase is initialized
    if (uid != null && isFirebaseInitialized) {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'notifications_list': list,
      }).catchError((e) { debugPrint('Error syncing notification to Firestore: $e'); });
    }
    
    // Trigger system notification
    showSystemNotification(title, body);
    
  } catch (e) { debugPrint('Error adding app notification: $e'); }
}
