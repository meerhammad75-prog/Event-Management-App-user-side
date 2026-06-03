class Event {
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final String imageUrl;

  Event({
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.imageUrl,
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