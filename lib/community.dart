import 'package:flutter/material.dart';
import 'group profile.dart';
import 'model/community_poll.dart';
import 'model/events.dart';

class CommunityScreen extends StatefulWidget {
  final List<Event> featuredEvents;
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const CommunityScreen({
    super.key,
    required this.featuredEvents,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<CommunityPoll> _polls = [
    CommunityPoll(
      id: "1",
      title: "What should be the next community event?",
      imageUrl: "assets/images/eventimage.png",
      options: [
        PollOption(text: "Business Networking Meetup", voteCount: '12k'),
        PollOption(text: "Startup Pitch Night", voteCount: '8k'),
      ],
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      selectedOptionIndex: null,
    ),
    CommunityPoll(
      id: "2",
      title: "Which workshop should we host?",
      imageUrl: "assets/images/eventimage.png",
      options: [
        PollOption(text: "Flutter Development Bootcamp", voteCount: '12k'),
        PollOption(text: "UI/UX Design Basics", voteCount: '9k'),
      ],
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      selectedOptionIndex: null,
    ),
    CommunityPoll(
      id: "3",
      title: "Preferred community activity?",
      imageUrl: "assets/images/eventimage.png",
      options: [
        PollOption(text: "Tech Talks", voteCount: '12k'),
        PollOption(text: "Hackathons", voteCount: '7k'),
      ],
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      selectedOptionIndex: null,
    ),
  ];

  void _onVote(int pollIndex, int optionIndex) {
    setState(() {
      _polls[pollIndex].selectedOptionIndex = optionIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    events: widget.featuredEvents,
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _polls.length,
        itemBuilder: (context, index) {
          return _buildPollCard(context, _polls[index], index);
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildPollCard(BuildContext context, CommunityPoll poll, int pollIndex) {
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
                child: Image.asset(
                  poll.imageUrl,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
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
                                        : colorScheme.onSurface
                                        .withOpacity(0.5),
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
}