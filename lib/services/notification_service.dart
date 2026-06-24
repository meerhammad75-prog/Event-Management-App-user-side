import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../model/notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── State ─────────────────────────────────────────────────────────────────
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  final List<NotificationModel> _localNotifications = [];

  // ── Public getter ─────────────────────────────────────────────────────────
  List<NotificationModel> get notifications => List.unmodifiable(_localNotifications);

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _initialized = true;
  }
  // ── Schedule reminder before event ────────────────────────────────────────
  static Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required DateTime eventTime,
  }) async {
    await init();
    final reminderTime = eventTime.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      '⏰ Event Reminder',
      '$title starts in 1 hour!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'event_reminders',
          'Event Reminders',
          channelDescription: 'Reminders for upcoming events',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel reminder ───────────────────────────────────────────────────────
  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  // ── Schedule and track ────────────────────────────────────────────────────
  static Future<void> scheduleAndTrack({
    required int id,
    required String title,
    required DateTime eventTime,
    required NotificationService instance,
    required String uid,
  }) async {
    await scheduleEventReminder(id: id, title: title, eventTime: eventTime);

    final reminderTime = eventTime.subtract(const Duration(hours: 1));
    final delay = reminderTime.difference(DateTime.now());

    if (delay.isNegative) return;

    Future.delayed(delay, () async {
      final notification = NotificationModel(
        id: id.toString(),
        message: '⏰ $title starts in 1 hour!',
        eventId: title,
        time: _formatTime(reminderTime),
        isRead: false,
      );

      instance._localNotifications.add(notification);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(id.toString())
            .set({
          'id': id.toString(),
          'message': notification.message,
          'eventId': notification.eventId,
          'time': notification.time,
          'isRead': false,
        });
      } catch (e) {
        debugPrint('Error saving notification: $e');
      }
    }); // ← closing Future.delayed
  }

  // ── Load notifications from Firestore ─────────────────────────────────────
  Future<void> loadNotifications(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      _localNotifications.clear();
      _localNotifications.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return NotificationModel(
            id: data['id'] ?? '',
            message: data['message'] ?? '',
            eventId: data['eventId'] ?? '',
            time: data['time'] ?? '',
            isRead: data['isRead'] ?? false,
            scheduledFor: (data['scheduledFor'] as Timestamp?)?.toDate(),
          );
        }).toList()
          ..sort((a, b) {
            final aTime = a.scheduledFor ?? _parseTime(a.time);
            final bTime = b.scheduledFor ?? _parseTime(b.time);
            return bTime.compareTo(aTime); // newest first
          }),
      );
    } catch (e) {
      debugPrint('🔔 Error loading notifications: $e');
    }
  }

// Converts "2:39 PM" style string to a comparable DateTime (uses today's date)
  DateTime _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(RegExp(r'[: ]'));
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final isPm = parts[2].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return DateTime(2000); // fallback to very old date if parsing fails
    }
  }
  // ── Mark as read ──────────────────────────────────────────────────────────
  Future<void> markAsRead(String id, String uid) async {
    final index = _localNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _localNotifications[index] = NotificationModel(
        id: _localNotifications[index].id,
        message: _localNotifications[index].message,
        eventId: _localNotifications[index].eventId,
        time: _localNotifications[index].time,
        isRead: true,
      );

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true});
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _formatTime(DateTime dt) {
    final hour =
    dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
  static Future<void> showPollNotification({
    required String pollId,
    required String question,
  }) async {
    await init();

    await _notifications.show(
      pollId.hashCode,
      '🗳️ New Poll Available!',
      '$question — cast your vote!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'poll_notifications',
          'Poll Notifications',
          channelDescription: 'Notifications for new polls',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
  static Future<void> showForegroundNotification({
    required String title,
    required String body,
  }) async {
    await init();
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'poll_notifications',
          'Poll Notifications',
          channelDescription: 'Notifications for new polls',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}