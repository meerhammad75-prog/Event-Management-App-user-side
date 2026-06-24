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
//
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
      _localNotifications.addAll(snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationModel(
          id: data['id'] ?? '',
          message: data['message'] ?? '',
          eventId: data['eventId'] ?? '',
          time: data['time'] ?? '',
          isRead: data['isRead'] ?? false,
        );
      }));
    } catch (e) {
      debugPrint('Error loading notifications: $e');
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
}