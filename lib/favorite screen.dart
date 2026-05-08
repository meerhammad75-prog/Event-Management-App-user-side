import 'package:flutter/material.dart';
import 'model/events.dart';

// ✅ ADDED
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
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[month - 1];
  }

  Widget _buildImage(String path) {
    if (path.startsWith("http")) {
      return Image.network(
        path,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey.shade300,
          child: Icon(Icons.image, size: 60, color: Colors.grey),
        ),
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: Colors.grey.shade300,
        child: Icon(Icons.image, size: 60, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Favourites",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: favoriteEvents.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 72, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text("No favourites yet",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            SizedBox(height: 8),
            Text("Tap the heart on any event to save it here",
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: favoriteEvents.length,
        itemBuilder: (context, index) =>
            _buildEventCard(context, favoriteEvents.elementAt(index)),
      ),
    );
  }

  // ✅ UPDATED WITH NAVIGATION
  Widget _buildEventCard(BuildContext context, Event event)  {
    final added = _isAdded(event);

    return GestureDetector(
      onTap: () => openEventDetail(
        context,
        event,
        favoriteEvents,
        addedEvents,
        onToggleFavorite,
        onAddToCalendar,
      ),      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
                  child: _buildImage(event.imageUrl),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => onToggleFavorite(event),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.transparent, shape: BoxShape.circle),
                      child: Icon(Icons.favorite,
                          color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 15, color: Colors.grey),
                      SizedBox(width: 6),
                      Text(_formatDateTime(event),
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 15, color: Colors.red),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(event.location,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13)),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                      added ? null : () => onAddToCalendar(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        added ? Colors.grey : Color(0xFFCF3232),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        added ? "Added" : "Add to my calendar",
                        style: TextStyle(color: Colors.white),
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
  }
}