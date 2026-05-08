import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'model/events.dart';

import 'helpers/event_navigation.dart';

class HomeTab extends StatefulWidget {
  final List<Event> allEvents;
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const HomeTab({
    super.key,
    required this.allEvents,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool isCalendarView = true;

  static const List<Color> _dotColors = [
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  List<Event> _getAddedEventsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return widget.addedEvents.where((e) {
      final eventDate =
      DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
      return eventDate == normalized;
    }).toList();
  }

  Color _colorForEvent(Event event) {
    final index = widget.allEvents.indexOf(event);
    if (index == -1) {
      return _dotColors[event.hashCode.abs() % _dotColors.length];
    }
    return _dotColors[index % _dotColors.length];
  }

  bool isAdded(Event event) => widget.addedEvents.contains(event);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Events",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: Image.asset(
              "assets/images/filter12.png",
              color: Colors.black,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.tune, color: Colors.black),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: _buildToggle(),
            ),
          ),

          // Calendar (only when in calendar view)
          if (isCalendarView)
            SliverToBoxAdapter(
              child: TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030),
                focusedDay: _focusedDay,
                rowHeight: 36,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _getAddedEventsForDay(day),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  headerPadding: EdgeInsets.symmetric(vertical: 4),
                  titleTextStyle: TextStyle(fontSize: 14),
                ),
                calendarStyle: const CalendarStyle(
                  cellMargin: EdgeInsets.zero,
                  cellPadding: EdgeInsets.zero,
                  markerDecoration:
                  BoxDecoration(color: Colors.transparent),
                  todayDecoration: BoxDecoration(
                      color: Color(0xFFCF3232), shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(
                      color: Color(0xFFCF3232), shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final eventsOnDay = _getAddedEventsForDay(day);
                    if (eventsOnDay.isEmpty) return const SizedBox.shrink();

                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: eventsOnDay.map((event) {
                          return Container(
                            width: 7,
                            height: 7,
                            margin:
                            const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                              color: _colorForEvent(event),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Spacing between calendar and cards
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Event cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(widget.allEvents[index]),
                childCount: widget.allEvents.length,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final added = isAdded(event);
    final isFav = widget.favoriteEvents.contains(event);
    final dotColor = _colorForEvent(event);

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildImage(event.imageUrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(_formatDateTime(event),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onToggleFavorite(event);
                    setState(() {});
                  },
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 5),
                Expanded(
                    child: Text(event.location,
                        style: TextStyle(color: Colors.grey[700]))),
              ],
            ),
            const SizedBox(height: 10),
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
                  backgroundColor: added ? Colors.grey : const Color(0xFFCF3232),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(added ? "Added" : "Add to my calendar",
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith("http")) {
      return Image.network(path, width: 50, height: 50, fit: BoxFit.cover);
    }
    return Image.asset(path, width: 50, height: 50, fit: BoxFit.cover);
  }

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

  void _showFilterDialog(BuildContext context) {
    String? selectedCity;
    String? selectedState;
    String? selectedGroup;
    Set<String> selectedCategories = {'Business'};

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 60,
              ),
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
                          child: const Icon(Icons.close, size: 22),
                        ),
                        const Text(
                          "Filter Events",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("City",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      hint: "Select City",
                      value: selectedCity,
                      items: const [
                        "New York",
                        "Los Angeles",
                        "Chicago",
                        "Houston"
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedCity = val),
                    ),
                    const SizedBox(height: 14),
                    const Text("State",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      hint: "Select State",
                      value: selectedState,
                      items: const [
                        "New Jersey",
                        "California",
                        "Texas",
                        "Florida"
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedState = val),
                    ),
                    const SizedBox(height: 14),
                    const Text("Groups",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      hint: "Group",
                      value: selectedGroup,
                      items: const ["Group A", "Group B", "Group C"],
                      onChanged: (val) =>
                          setDialogState(() => selectedGroup = val),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final chipWidth = (constraints.maxWidth - 12) / 3;
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            SizedBox(
                                width: chipWidth,
                                child: _buildChip("Religious",
                                    Icons.star_border, selectedCategories, setDialogState)),
                            SizedBox(
                                width: chipWidth,
                                child: _buildChip("Business",
                                    Icons.business, selectedCategories, setDialogState)),
                            SizedBox(
                                width: chipWidth,
                                child: _buildChip("Fitness",
                                    Icons.fitness_center, selectedCategories, setDialogState)),
                            SizedBox(
                                width: chipWidth,
                                child: _buildChip("Education",
                                    Icons.school, selectedCategories, setDialogState)),
                            SizedBox(
                                width: chipWidth,
                                child: _buildChip("Community",
                                    Icons.people, selectedCategories, setDialogState)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedCity = null;
                                selectedState = null;
                                selectedGroup = null;
                                selectedCategories.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.black, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Clear Filter",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCF3232),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Apply Filter",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isCalendarView = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isCalendarView
                        ? const Color(0xFFCF3232)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Calendar View",
                      style: TextStyle(
                        color: isCalendarView ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isCalendarView = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !isCalendarView
                        ? const Color(0xFFCF3232)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "List View",
                      style: TextStyle(
                        color: !isCalendarView ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildChip(
      String label,
      IconData icon,
      Set<String> selected,
      StateSetter setDialogState,
      ) {
    final isSelected = selected.contains(label);

    return GestureDetector(
      onTap: () {
        setDialogState(() {
          if (isSelected) {
            selected.remove(label);
          } else {
            selected.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCF3232) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCF3232)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}