// lib/services/notification_service.dart
//
// When you have a real backend, replace fetchNotifications() body with:
//   final response = await http.get(Uri.parse('$baseUrl/notifications'));
//   final List data = jsonDecode(response.body);
//   return data.map((e) => NotificationModel.fromJson(e)).toList();
//
// Your API response should include "event_id" matching your Event titles/IDs.

import '../model/notification.dart';

class NotificationService {
  Future<List<NotificationModel>> fetchNotifications() async {
    // Simulates a network delay so the loading spinner shows correctly
    await Future.delayed(const Duration(milliseconds: 600));

    // ── MOCK DATA ────────────────────────────────────────────────────────────
    // eventId here matches Event.title from your events list.
    // When you switch to a real API, the backend sends the actual event ID.
    // ─────────────────────────────────────────────────────────────────────────
    return [
      NotificationModel(
        id: '1',
        message: 'Your event starts in 1 hour. Don\'t be late!',
        time: '4:00 pm',
        isRead: false,
        eventId: null, // will cycle through events by index
      ),
      NotificationModel(
        id: '2',
        message: 'New event added near you. Check it out!',
        time: '3:30 pm',
        isRead: false,
        eventId: null,
      ),
      NotificationModel(
        id: '3',
        message: 'Reminder: your saved event is tomorrow.',
        time: '2:15 pm',
        isRead: false,
        eventId: null,
      ),
      NotificationModel(
        id: '4',
        message: 'Your friend joined an event you liked.',
        time: '1:00 pm',
        isRead: true,
        eventId: null,
      ),
      NotificationModel(
        id: '5',
        message: 'An event you saved has been updated.',
        time: '11:45 am',
        isRead: true,
        eventId: null,
      ),
      NotificationModel(
        id: '6',
        message: 'You have a new message from the organizer.',
        time: '10:00 am',
        isRead: true,
        eventId: null,
      ),
      NotificationModel(
        id: '7',
        message: 'Your ticket has been confirmed. See you there!',
        time: '9:30 am',
        isRead: true,
        eventId: null,
      ),
      NotificationModel(
        id: '8',
        message: 'Don\'t miss out — event starts this Friday.',
        time: '8:00 am',
        isRead: true,
        eventId: null,
      ),
    ];
  }

  // ── TODO: replace with real API call ─────────────────────────────────────
  // await http.patch(Uri.parse('$baseUrl/notifications/$id/read'));
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}