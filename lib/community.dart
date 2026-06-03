import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'AdminCommunityScreen.dart';
import 'group profile.dart';
import 'model/community_poll.dart';
import 'model/events.dart';

class CommunityScreen extends StatefulWidget {
  final String role;
  // featuredEvents removed – passed only to GroupProfileScreen now
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const CommunityScreen({
    super.key,
    required this.role,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<CommunityPoll> _polls = [];
  bool _isLoading = true;

  bool get isAdmin => widget.role == 'Admin';

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  Future<void> _fetchPolls() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('polls')
          .orderBy('createdAt', descending: true)
          .get();

      final polls = snapshot.docs
          .map((doc) => CommunityPoll.fromFirestore(doc))
          .toList();

      if (mounted) setState(() { _polls = polls; _isLoading = false; });
    } catch (e) {
      debugPrint('CommunityScreen fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onVote(int pollIndex, int optionIndex) {
    setState(() {
      _polls[pollIndex].selectedOptionIndex = optionIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Admin gets their own dedicated screen
    if (isAdmin) {
      return AdminCommunityScreen(
        favoriteEvents: widget.favoriteEvents,
        addedEvents: widget.addedEvents,
        onToggleFavorite: widget.onToggleFavorite,
        onAddToCalendar: widget.onAddToCalendar,
      );
    }

    // User view
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFCF3232),
        elevation: 0,
        title: const Text(
          "Business group",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupProfileScreen(
                    events: const [],
                    favoriteEvents: widget.favoriteEvents,
                    addedEvents: widget.addedEvents,
                    onToggleFavorite: widget.onToggleFavorite,
                    onAddToCalendar: widget.onAddToCalendar,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/Ellipse.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        actions: const [
          Icon(Icons.more_vert, color: Colors.white),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFCF3232)))
          : _polls.isEmpty
          ? const Center(child: Text('No polls yet.'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _polls.length,
        itemBuilder: (context, index) {
          return _buildPollCard(context, _polls[index], index);
        },
      ),
    );
  }

  Widget _buildPollCard(
      BuildContext context, CommunityPoll poll, int pollIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (pollIndex == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Today",
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: isDark
                      ? Colors.black38
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
                child: _buildPollImage(poll.imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(poll.options.length, (optIndex) {
                      final option = poll.options[optIndex];
                      final isSelected = poll.selectedOptionIndex == optIndex;
                      final label = String.fromCharCode(65 + optIndex);

                      return GestureDetector(
                        onTap: () => _onVote(pollIndex, optIndex),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 22,
                                child: Text("$label.",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: colorScheme.onSurface)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFCF3232)
                                        : colorScheme.onSurface.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFCF3232)
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.circle,
                                    color: Colors.white, size: 10)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(option.text,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurface)),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.formattedVotes,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        poll.timeAgo,
                        style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url,
          height: 190,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              height: 190,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image, size: 60, color: Colors.grey)));
    }
    return Image.asset(url,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            height: 190,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image, size: 60, color: Colors.grey)));
  }
}
