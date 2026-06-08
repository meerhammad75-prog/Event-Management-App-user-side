import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'helpers/event_navigation.dart';
import 'model/events.dart';
import 'dart:io' as dart_io;

class FeaturesScreen extends StatefulWidget {
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const FeaturesScreen({
    super.key,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}


class _FeaturesScreenState extends State<FeaturesScreen> {
  List<Event> featuredEvents = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _eventsSub;
  String? _activeCity;
  String? _activeState;
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
          category:  data['category'] ?? 'Other', // ADD
          city:      data['city']     ?? '',
          state:     data['state']    ?? '',
        );
      }).toList();

      if (mounted) setState(() { featuredEvents = events; _isLoading = false; });
    }, onError: (e) {
      debugPrint('FeaturesScreen stream error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  bool _isAdded(Event event) => widget.addedEvents.contains(event);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        title: const Text("Features",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: Icon(Icons.tune, color: colorScheme.onSurface),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFCF3232)))
          : featuredEvents.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      )
          : Builder(builder: (context) {
        final visibleEvents = featuredEvents.where((e) {
          if (_activeCity  != null && e.city  != _activeCity)  return false;
          if (_activeState != null && e.state != _activeState) return false;
          return true;
        }).toList();
        return visibleEvents.isEmpty
            ? Center(
          child: Text(
            'No events for selected filter',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 15,
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: visibleEvents.length,
          itemBuilder: (context, index) =>
              _buildEventCard(context, visibleEvents[index]),
        );
      }),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
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
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
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
                  Text(
                    event.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 15,
                          color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text(_formatDateTime(event),
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
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
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAdded(event)
                          ? null
                          : () {
                        widget.onAddToCalendar(event);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdded(event)
                            ? Colors.grey
                            : const Color(0xFFCF3232),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _isAdded(event)
                            ? "Added to Calendar ✓"
                            : "Add to my calendar",
                        style: const TextStyle(color: Colors.white),
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

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String? selectedCity = _activeCity;
    String? selectedState = _activeState;
    String? selectedGroup;

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: theme.dialogBackgroundColor,
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 60),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close,
                                size: 22, color: colorScheme.onSurface)),
                        Text("Filter Events",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface)),
                        const SizedBox(width: 22),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text("City",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                        context: context,
                        hint: "Select City",
                        value: selectedCity,
                        items: ["Lahore", "Karachi", "Islamabad", "Rawalpindi", "Peshawar"],
                        onChanged: (val) =>
                            setDialogState(() => selectedCity = val)),
                    const SizedBox(height: 14),
                    Text("State",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                        context: context,
                        hint: "Select State",
                        value: selectedState,
                        items: [
                          "Punjab", "Sindh", "KPK", "Balochistan", "Federal"
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedState = val)),
                    const SizedBox(height: 14),
                    Text("Groups",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                        context: context,
                        hint: "Group",
                        value: selectedGroup,
                        items: ["Group A", "Group B", "Group C"],
                        onChanged: (val) =>
                            setDialogState(() => selectedGroup = val)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _activeCity  = null;
                                _activeState = null;
                              });
                              setDialogState(() {
                                selectedCity  = null;
                                selectedState = null;
                                selectedGroup = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: colorScheme.onSurface, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text("Clear Filter",
                                style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _activeCity  = selectedCity;
                                _activeState = selectedState;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCF3232),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Apply Filter",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7))),
          value: value,
          dropdownColor: Theme.of(context).dialogBackgroundColor,
          style: TextStyle(color: colorScheme.onSurface),
          icon: Icon(Icons.keyboard_arrow_down,
              color: colorScheme.onSurface),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}