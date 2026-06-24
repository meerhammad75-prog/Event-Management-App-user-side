import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String message;
  final String time;
  final bool isRead;
  final String? eventId;
  final DateTime? scheduledFor; // ← ADD

  NotificationModel({
    required this.id,
    required this.message,
    required this.time,
    required this.isRead,
    this.eventId,
    this.scheduledFor, // ← ADD
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      time: json['time'] ?? '',
      isRead: json['isRead'] ?? false,
      eventId: json['eventId'],
      scheduledFor: (json['scheduledFor'] as Timestamp?)?.toDate(), // ← ADD
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'time': time,
      'isRead': isRead,
      'eventId': eventId,
      'scheduledFor': scheduledFor != null  // ← ADD
          ? Timestamp.fromDate(scheduledFor!)
          : null,
    };
  }
}