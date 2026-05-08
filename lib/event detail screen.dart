import 'package:flutter/material.dart';
import 'model/events.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  static const Color _red = Color(0xFFCF3232);

  bool get _isFav => widget.favoriteEvents.contains(widget.event);
  bool get _isAdded => widget.addedEvents.contains(widget.event);

  String _formatDateTime(Event event) {
    return "${event.startTime.day} ${_monthName(event.startTime.month)} "
        "${event.startTime.year} ${_formatTime(event.startTime)} GMT";
  }

  String _formatTime(DateTime dt) {
    int hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    if (hour == 0) hour = 12;
    String period = dt.hour >= 12 ? "pm" : "am";
    return "$hour:${dt.minute.toString().padLeft(2, '0')}$period";
  }

  String _monthName(int month) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[month - 1];
  }

  Widget _buildImage() {
    final path = widget.event.imageUrl;
    if (path.startsWith("http")) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
      );
    }
    return Image.asset(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Full-width image with back + heart overlay ──────────
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),

                // Dark gradient at top for icon visibility
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),

                // Back arrow
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 26),
                  ),
                ),

                // Heart icon
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      widget.onToggleFavorite(widget.event);
                      setState(() {});
                    },
                    child: Icon(
                      _isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Details section ─────────────────────────────────────
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(widget.event),
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.black87),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.event.location,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Event Detail heading
                  const Text(
                    'Event Detail',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Description box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Lorem ipsum dolor sit amet consectetur. Sed volutpat euismod enim accumsan quam posuere. Tortor pretium lorem dui metus amet in sed. Sodales volutpat maecenas et quisque nibh ultrices in nulla. Enim fames quam turpis pellentesque vivamus massa.Lorem ipsum dolor sit amet consectetur. Sed volutpat euismod enim accumsan quam posuere. Tortor pretium lorem dui metus amet in sed. Sodales volutpat maecenas et quisque nibh ultrices in nulla. Enim fames quam turpis pellentesque vivamus massa.Lorem ipsum dolor sit amet consectetur. Sed volutpat euismod enim accumsan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF444444),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add to calendar button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAdded
                          ? null
                          : () {
                        widget.onAddToCalendar(widget.event);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdded ? Colors.grey : _red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isAdded ? 'Added' : 'Add to my calendar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}