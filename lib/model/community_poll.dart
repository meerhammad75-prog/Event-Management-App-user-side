import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24)   return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  /// Build a CommunityPoll from a Firestore document
  factory CommunityPoll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawOptions = data['options'] as List<dynamic>? ?? [];

    return CommunityPoll(
      id:       doc.id,
      title:    data['question'] ?? '',
      imageUrl: data['imageUrl'] ?? 'assets/images/eventimage.png',
      postedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      options:  rawOptions.map((o) => PollOption.fromMap(o)).toList(),
    );
  }

  /// Convert to map for Firestore (used when creating)
  Map<String, dynamic> toMap() => {
    'question':  title,
    'imageUrl':  imageUrl,
    'options':   options.map((o) => o.toMap()).toList(),
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class PollOption {
  final String text;
  final String voteCount;

  PollOption({required this.text, required this.voteCount});

  factory PollOption.fromMap(Map<String, dynamic> map) => PollOption(
    text:      map['text'] ?? '',
    voteCount: map['voteCount'] ?? '0',
  );

  Map<String, dynamic> toMap() => {
    'text':      text,
    'voteCount': voteCount,
  };

  String get formattedVotes => "$voteCount votes";
}