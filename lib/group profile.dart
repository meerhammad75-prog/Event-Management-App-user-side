import 'package:flutter/material.dart';
import 'model/events.dart';
import 'helpers/event_navigation.dart';

class GroupProfileScreen extends StatefulWidget {
  final List<Event> events;
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const GroupProfileScreen({
    super.key,
    required this.events,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  static const Color _red = Color(0xFFCF3232);
  static const Color _lightRed = Color(0xFFFDE8E8);

  // ── Helpers ────────────────────────────────────────────────────
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

  Widget _buildImage(String path) {
    if (path.startsWith("http")) {
      return Image.network(path,
          width: double.infinity, height: 200, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              height: 200, color: Colors.grey.shade300,
              child: const Icon(Icons.image, size: 60, color: Colors.grey)));
    }
    return Image.asset(path,
        width: double.infinity, height: 200, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            height: 200, color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 60, color: Colors.grey)));
  }

  // ── Event card ─────────────────────────────────────────────────
  Widget _buildEventCard(Event event) {
    final added = widget.addedEvents.contains(event);
    final isFav = widget.favoriteEvents.contains(event);

    return GestureDetector(
      onTap: () => openEventDetail(
        context, event,
        widget.favoriteEvents, widget.addedEvents,
        widget.onToggleFavorite, widget.onAddToCalendar,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + heart
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _buildImage(event.imageUrl),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      widget.onToggleFavorite(event);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.transparent, // ✅ fully transparent now
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white, // visible on image
                        size: 20,
                      ),
                    ),                  ),
                ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(_formatDateTime(event),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.location,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: added
                          ? null
                          : () {
                        widget.onAddToCalendar(event);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: added ? Colors.grey : _red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        added ? "Added" : "Add to my calendar",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [

          // ── Red header with overlapping avatar ─────────────────
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Red background
                Container(
                  height: 140,
                  color: _red,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child:
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 24),
                          ),

                          const SizedBox(width: 12),

                          const Text(
                            'Group Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Spacer(), // ⭐ pushes everything to right

                          const Icon(Icons.more_vert,
                              color: Colors.white, size: 24),
                        ],
                      ),                    ),
                  ),
                ),

                // Overlapping circular avatar
                Positioned(
                  bottom: -45,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Ellipse.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── White info section ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 56), // space for avatar overlap
                  const Text(
                    'Business group',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Lorem ipsum dolor sit amet consectetur. Cras elit volutpat morbi mauris tincidunt lacus.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Members badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: _lightRed,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      '14K Members',
                      style: TextStyle(
                        color: _red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── "Group Events" heading ─────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Group Events',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // ── Event cards ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(widget.events[index]),
                childCount: widget.events.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}