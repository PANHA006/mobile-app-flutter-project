
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // To access isFirebaseInitialized

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
  } catch (e) { debugPrint('Error adding app notification: $e'); }
}
