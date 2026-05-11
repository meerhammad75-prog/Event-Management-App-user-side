import 'package:flutter/material.dart';
import 'model/events.dart';
import 'helpers/event_navigation.dart';

class FavouriteScreen extends StatelessWidget {
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const FavouriteScreen({
    super.key,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  bool _isAdded(Event event) => addedEvents.contains(event);

  String _formatDateTime(Event event) {
    return "${event.startTime.day} ${_monthName(event.startTime.month)} ${event.startTime.year}, "
        "${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}";
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    if (hour == 0) hour = 12;
    String period = dt.hour >= 12 ? "PM" : "AM";
    return "$hour:${dt.minute.toString().padLeft(2, '0')} $period";
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Widget _buildImage(String path, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Widget placeholder = Container(
      height: 200,
      color: colorScheme.surfaceVariant,
      child: Icon(Icons.image, size: 60, color: colorScheme.onSurfaceVariant),
    );

    if (path.startsWith("http")) {
      return Image.network(path,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder);
    }
    return Image.asset(path,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: Text("Favourites",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: favoriteEvents.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 72,
                color: colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text("No favourites yet",
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: favoriteEvents.length,
        itemBuilder: (context, index) {
          final event = favoriteEvents.elementAt(index);
          final added = _isAdded(event);

          return GestureDetector(
            onTap: () => openEventDetail(
              context,
              event,
              favoriteEvents,
              addedEvents,
              onToggleFavorite,
              onAddToCalendar,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: isDark ? Colors.black38 : Colors.black12,
                      blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: _buildImage(event.imageUrl, context),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => onToggleFavorite(event),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 15,
                                color: colorScheme.onSurface
                                    .withOpacity(0.6)),
                            const SizedBox(width: 6),
                            Text(_formatDateTime(event),
                                style: TextStyle(
                                    color: colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 15, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(event.location,
                                  style: TextStyle(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                      fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: added
                                ? null
                                : () => onAddToCalendar(event),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: added
                                  ? Colors.grey
                                  : const Color(0xFFCF3232),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                            ),
                            child: Text(
                              added
                                  ? "Added to Calendar ✓"
                                  : "Add to my calendar",
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}