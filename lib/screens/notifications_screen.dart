import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/system_notification.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final NotificationService _notificationService = NotificationService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: Center(child: Text('Please login to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder<List<SystemNotification>>(
        stream: _notificationService.getUserNotifications(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(child: Text('No new notifications'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: Icon(
                  notif.type == 'rescue' 
                    ? Icons.healing 
                    : notif.type == 'adoption' 
                      ? Icons.pets 
                      : Icons.chat,
                  color: notif.isRead ? Colors.grey : Colors.blue,
                ),
                title: Text(
                  notif.title, 
                  style: TextStyle(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                  )
                ),
                subtitle: Text('${notif.message}\n${_formatDate(notif.createdAt)}'),
                isThreeLine: true,
                onTap: () {
                  if (!notif.isRead) {
                    _notificationService.markAsRead(notif.id);
                  }
                  // Further deep linking can happen here depending on notif.type
                },
              );
            },
          );
        },
      ),
    );
  }
}
