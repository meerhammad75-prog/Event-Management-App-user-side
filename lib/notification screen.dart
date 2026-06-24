import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagementapp/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/events.dart';
import 'model/notification.dart';
import '../helpers/event_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  final List<Event> allEvents;
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const NotificationsScreen({
    super.key,
    required this.allEvents,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  List<Event> _allEventsFromFirestore = []; // ← ADD

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadAllEvents(); // ← ADD

  }
  Future<void> _loadAllEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .get();

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          imageUrl: data['imageUrl'] ?? 'assets/images/eventimage.png',
          category: data['category'] ?? 'Other',
          city: data['city'] ?? '',
          state: data['state'] ?? '',
          description: data['detail'] ?? '',
        );
      }).toList();

      if (mounted) setState(() => _allEventsFromFirestore = events);
    } catch (e) {
      debugPrint('Error loading all events: $e');
    }
  }
  Future<void> _loadNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _service.loadNotifications(uid);

      setState(() {
        _notifications = List.from(_service.notifications);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final n = _notifications[index];
    if (n.isRead) return;

    await _service.markAsRead(n.id, uid);

    setState(() {
      _notifications[index] = NotificationModel(
        id: n.id,
        message: n.message,
        eventId: n.eventId,
        time: n.time,
        isRead: true,
      );
    });
  }

  String _imageUrlFor(NotificationModel notification, int index) {
    // Search in all events from Firestore
    if (notification.eventId != null && notification.eventId!.isNotEmpty) {
      try {
        return _allEventsFromFirestore
            .firstWhere((e) => e.title == notification.eventId)
            .imageUrl;
      } catch (_) {}
    }
    // Fallback to today's events
    if (widget.allEvents.isEmpty) return '';
    return widget.allEvents[index % widget.allEvents.length].imageUrl;
  }

  Event? _eventFor(NotificationModel notification, int index) {
    // Search in all events from Firestore
    if (notification.eventId != null && notification.eventId!.isNotEmpty) {
      try {
        return _allEventsFromFirestore
            .firstWhere((e) => e.title == notification.eventId);
      } catch (_) {}
    }
    // Fallback to today's events
    if (widget.allEvents.isEmpty) return null;
    return widget.allEvents[index % widget.allEvents.length];
  }


  Widget _buildImage(String path, BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(context),
      );
    }
    if (path.isEmpty) return _imageFallback(context);
    return Image.asset(
      path,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(context),
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: Theme.of(context).dividerColor,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFCC2222)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC2222)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text('No notifications yet.', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFCC2222),
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final imageUrl = _imageUrlFor(notification, index);
          final event = _eventFor(notification, index);

          return _NotificationCard(
            notification: notification,
            imageWidget: _buildImage(imageUrl, context),
            onTap: () async {
              await _markAsRead(index);
              if (!context.mounted) return;

              // Poll notification → go back with 'community' result
              if (notification.id.startsWith('poll_')) {
                Navigator.pop(context, 'community');
                return;
              }

              // Event notification → open event detail
              if (event != null) {
                openEventDetail(
                  context,
                  event,
                  widget.favoriteEvents,
                  widget.addedEvents,
                  widget.onToggleFavorite,
                  widget.onAddToCalendar,
                );
              }
            },          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Widget imageWidget;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.imageWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageWidget,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.message,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!notification.isRead)
                  const Icon(Icons.circle, color: Color(0xFFCC2222), size: 10),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: notification.isRead ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}