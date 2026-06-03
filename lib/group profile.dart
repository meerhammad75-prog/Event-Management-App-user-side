import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'model/events.dart';
import 'helpers/event_navigation.dart';
import 'dart:io' as dart_io;

class GroupProfileScreen extends StatefulWidget {
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const GroupProfileScreen({
    super.key,
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

  List<Event> _events = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _subscribeToEvents();
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _subscribeToEvents() {
    _eventsSub = FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          imageUrl: data['imageUrl'] ?? 'assets/images/eventimage.png',
        );
      }).toList();

      if (mounted) setState(() { _events = events; _isLoading = false; });
    }, onError: (e) {
      debugPrint('GroupProfileScreen stream error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

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
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  Widget _buildImage(String path) {
    final placeholder = (_, __, ___) => Container(
        height: 200,
        color: Colors.grey.shade400,
        child: const Icon(Icons.image, size: 60, color: Colors.grey));

    if (path.startsWith("http")) {
      return Image.network(path,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: placeholder);
    }
    if (path.startsWith("/")) {
      return Image.file(dart_io.File(path),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: placeholder);
    }
    return Image.asset(path,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: placeholder);
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final added = widget.addedEvents.contains(event);
    final isFav = widget.favoriteEvents.contains(event);

    return GestureDetector(
      onTap: () => openEventDetail(
        context,
        event,
        widget.favoriteEvents,
        widget.addedEvents,
        widget.onToggleFavorite,
        widget.onAddToCalendar,
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
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                        size: 20,
                      ),
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
                          fontSize: 15,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text(_formatDateTime(event),
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface
                                  .withOpacity(0.6))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(event.location,
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface
                                    .withOpacity(0.6))),
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
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 140,
                  color: _red,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
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
                          const Spacer(),
                          const Icon(Icons.more_vert,
                              color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
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
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Text(
                    'Business group',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Lorem ipsum dolor sit amet consectetur. Cras elit volutpat morbi mauris tincidunt lacus.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Group Events',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFFCF3232)),
                ),
              ),
            )
          else if (_events.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_note,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('No events found',
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                      _buildEventCard(context, _events[index]),
                  childCount: _events.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
