class CommunityPoll {
  final String id;
  final String title;
  final String imageUrl;
  final List<PollOption> options;
  final DateTime postedAt;
  int? selectedOptionIndex;

  CommunityPoll({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.options,
    required this.postedAt,
    this.selectedOptionIndex,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else {
      return "${diff.inDays}d ago";
    }
  }
}

class PollOption {
  final String text;
  final String voteCount;

  PollOption({
    required this.text,
    required this.voteCount,
  });

  String get formattedVotes {
    return "$voteCount votes";
  }
}