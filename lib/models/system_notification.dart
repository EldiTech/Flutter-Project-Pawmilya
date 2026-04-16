import 'package:cloud_firestore/cloud_firestore.dart';

class SystemNotification {
  final String id;
  final String title;
  final String message;
  final String recipientId; // User ID who should receive it
  final String type; // e.g. 'rescue', 'adoption', 'chat'
  final bool isRead;
  final DateTime createdAt;

  SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.recipientId,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory SystemNotification.fromMap(Map<String, dynamic> data, String id) {
    return SystemNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      recipientId: data['recipientId'] ?? '',
      type: data['type'] ?? 'system',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'recipientId': recipientId,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
