class Event {
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String imageUrl;
  final String category; // ADD
  final String city;     // ADD
  final String state;
  final String description;

  Event({
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
    this.category = 'Other', // ADD
    this.city     = '',      // ADD
    this.state    = '',      // ADD
    this.description = '', // ← ADD

  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Event &&
              runtimeType == other.runtimeType &&
              title == other.title &&
              startTime == other.startTime;

  @override
  int get hashCode => title.hashCode ^ startTime.hashCode;
}