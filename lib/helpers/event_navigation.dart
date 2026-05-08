import 'package:flutter/material.dart';
import '../event detail screen.dart';
import '../model/events.dart';

/// Call this from ANY screen to open the Event Detail screen.
///
/// Usage:
///   openEventDetail(context, event, favoriteEvents, addedEvents,
///                  onToggleFavorite, onAddToCalendar);
void openEventDetail(
    BuildContext context,
    Event event,
    Set<Event> favoriteEvents,
    Set<Event> addedEvents,
    Function(Event) onToggleFavorite,
    Function(Event) onAddToCalendar,
    ) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EventDetailScreen(
        event: event,
        favoriteEvents: favoriteEvents,
        addedEvents: addedEvents,
        onToggleFavorite: onToggleFavorite,
        onAddToCalendar: onAddToCalendar,
      ),
    ),
  );
}