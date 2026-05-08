import 'package:flutter/material.dart';
import 'helpers/event_navigation.dart';
import 'model/events.dart';

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
  final List<Event> featuredEvents = [
    Event(
      title: "Made in Melanin! Black History Month Social",
      location: "1901 Thornridge Cir. Shiloh, Hawaii 81063",
      startTime: DateTime(2025, 10, 28, 18, 0),
      endTime: DateTime(2025, 10, 28, 20, 0),
      imageUrl: "assets/images/eventimage.png",
    ),
    Event(
      title: "Made in Melanin! Black History Month Social",
      location: "1901 Thornridge Cir. Shiloh, Hawaii 81063",
      startTime: DateTime(2025, 10, 28, 19, 0),  // different startTime
      endTime: DateTime(2025, 10, 28, 21, 0),
      imageUrl: "assets/images/eventimage.png",
    ),
    Event(
      title: "Made in av! Black History Month Social",
      location: "1901 Thornridge Cir. Shiloh, Hawaii 81063",
      startTime: DateTime(2025, 10, 28, 18, 0),
      endTime: DateTime(2025, 10, 28, 20, 0),
      imageUrl: "assets/images/eventimage.png",
    ),
  ];

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
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[month - 1];
  }

  Widget _buildImage(String path) {
    if (path.startsWith("http")) {
      return Image.network(path,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey.shade300,
              child: Icon(Icons.image, size: 60, color: Colors.grey)));
    }
    return Image.asset(path,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Colors.grey.shade300,
            child: Icon(Icons.image, size: 60, color: Colors.grey)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
        Text("Features", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: Icon(Icons.tune),
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: featuredEvents.length,
        itemBuilder: (context, index) =>
            _buildEventCard(featuredEvents[index]),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
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
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── IMAGE + HEART ─────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
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
                  ),                ),
              ],
            ),

            // ── DETAILS ──────────────────────────────────
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
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
                                color: Colors.grey[700],
                                fontSize: 13)),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAdded(event)
                          ? null  // disable if already added
                          : () {
                        widget.onAddToCalendar(event);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdded(event)
                            ? Colors.grey
                            : Color(0xFFCF3232),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        _isAdded(event) ? "Added to Calendar ✓" : "Add to my calendar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showFilterDialog(BuildContext context) {
    String? selectedCity;
    String? selectedState;
    String? selectedGroup;

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding:
              EdgeInsets.symmetric(horizontal: 11, vertical: 60),
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
                            child: Icon(Icons.close, size: 22)),
                        Text("Filter Events",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 22),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text("City",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    _buildDropdown(
                        hint: "Select City",
                        value: selectedCity,
                        items: ["New York", "Los Angeles", "Chicago", "Houston"],
                        onChanged: (val) =>
                            setDialogState(() => selectedCity = val)),
                    SizedBox(height: 14),
                    Text("State",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    _buildDropdown(
                        hint: "Select State",
                        value: selectedState,
                        items: ["New Jersey", "California", "Texas", "Florida"],
                        onChanged: (val) =>
                            setDialogState(() => selectedState = val)),
                    SizedBox(height: 14),
                    Text("Groups",
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    _buildDropdown(
                        hint: "Group",
                        value: selectedGroup,
                        items: ["Group A", "Group B", "Group C"],
                        onChanged: (val) =>
                            setDialogState(() => selectedGroup = val)),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setDialogState(() {
                              selectedCity = null;
                              selectedState = null;
                              selectedGroup = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.black, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text("Clear Filter",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFCF3232),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text("Apply Filter",
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
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.black87)),
          value: value,
          icon: Icon(Icons.keyboard_arrow_down),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}