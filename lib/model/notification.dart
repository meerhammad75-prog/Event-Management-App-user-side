// lib/model/notification_model.dart

class NotificationModel {
  final String id;
  final String message;
  final String time;
  final bool isRead;

  // Links this notification to an Event so the screen shows that event's image.
  // Your backend API should return this field (event_id).
  final String? eventId;

  NotificationModel({
    required this.id,
    required this.message,
    required this.time,
    required this.isRead,
    this.eventId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      message: json['message'] ?? '',
      time: json['time'] ?? '',
      isRead: json['is_read'] ?? false,
      eventId: json['event_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'time': time,
      'is_read': isRead,
      'event_id': eventId,
    };
  }
}