import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/system_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Local Notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // Request permissions for iOS and Android 13+
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Save device token to user's database
      _saveDeviceToken();

      // Listen to incoming messages in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          _showLocalNotification(
            message.notification!.title,
            message.notification!.body,
          );
        }
      });
    }
  }

  Future<void> _saveDeviceToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      String? token = await _fcm.getToken();
      if (token != null) {
        // You would typically save this alongside the user doc
        // e.g. _firestore.collection('users').doc(user.uid).update({'fcmToken': token});
      }
    }
  }

  Future<void> _showLocalNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pawmilya_sys_channel',
          'Pawmilya Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // Create an In-App Notification in Firestore
  Future<void> createNotification({
    required String title,
    required String message,
    required String recipientId,
    required String type,
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    final notif = SystemNotification(
      id: docRef.id,
      title: title,
      message: message,
      recipientId: recipientId,
      type: type,
      createdAt: DateTime.now(),
    );
    await docRef.set(notif.toMap());
  }

  // Stream notifications for current user
  Stream<List<SystemNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SystemNotification.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}
