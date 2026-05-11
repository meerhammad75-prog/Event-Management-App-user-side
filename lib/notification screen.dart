// lib/screens/notifications_screen.dart

import 'package:eventmanagementapp/services/notification%20service.dart';
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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final data = await _service.fetchNotifications();
      setState(() {
        _notifications = data;
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
    final n = _notifications[index];
    if (n.isRead) return;
    await _service.markAsRead(n.id);
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

  // Cycles through allEvents by index — uses whichever images your app already has
  String _imageUrlFor(NotificationModel notification, int index) {
    if (widget.allEvents.isEmpty) return '';
    if (notification.eventId != null && notification.eventId!.isNotEmpty) {
      final match = widget.allEvents.firstWhere(
            (e) => e.title == notification.eventId,
        orElse: () => widget.allEvents[index % widget.allEvents.length],
      );
      return match.imageUrl;
    }
    return widget.allEvents[index % widget.allEvents.length].imageUrl;
  }

  // Finds the Event linked to this notification (for navigation)
  Event? _eventFor(NotificationModel notification, int index) {
    if (widget.allEvents.isEmpty) return null;
    if (notification.eventId != null && notification.eventId!.isNotEmpty) {
      try {
        return widget.allEvents.firstWhere(
              (e) => e.title == notification.eventId,
        );
      } catch (_) {}
    }
    return widget.allEvents[index % widget.allEvents.length];
  }

  // Same helper used in FeaturesScreen and HomeTab —
  // handles both "assets/images/..." and "https://..." correctly
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

    if (path.isEmpty) {
      return _imageFallback(context);
    }

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
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
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text('No notifications yet.',
            style: TextStyle(color: Colors.grey)),
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
            imageWidget: _buildImage(imageUrl, context),            onTap: () async {
            await _markAsRead(index);
            if (event != null && context.mounted) {
              openEventDetail(
                context,
                event,
                widget.favoriteEvents,
                widget.addedEvents,
                widget.onToggleFavorite,
                widget.onAddToCalendar,
              );
            }
          },
          );
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
          color: Theme.of(context).cardColor,          borderRadius: BorderRadius.circular(12),
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
            // Event image — asset or network, handled by _buildImage
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageWidget,
            ),
            const SizedBox(width: 12),

            // Message
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

            // Unread dot + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!notification.isRead)
                  const Icon(Icons.circle,
                      color: Color(0xFFCC2222), size: 10),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    notification.isRead ? Colors.grey : Colors.black87,
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