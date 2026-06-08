import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'AdminCommunityScreen.dart';
import 'group profile.dart';
import 'model/community_poll.dart';
import 'model/events.dart';

class CommunityScreen extends StatefulWidget {
  final String role;
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
  // pollId -> optionIndex the current user has voted for
  final Map<String, int> _userVotes = {};
  // pollId -> true while a vote is being submitted
  final Map<String, bool> _votingInProgress = {};

  StreamSubscription<QuerySnapshot>? _pollsSub;
  List<CommunityPoll> _polls = [];
  bool _isLoading = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  bool get isAdmin => widget.role == 'Admin';

  // ── lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (!isAdmin) {
      _subscribeToPolls();
    }
  }

  @override
  void dispose() {
    _pollsSub?.cancel();
    super.dispose();
  }

  // ── real-time poll stream ────────────────────────────────────────────────────

  void _subscribeToPolls() {
    _pollsSub = FirebaseFirestore.instance
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final polls = snapshot.docs
          .map((doc) => CommunityPoll.fromFirestore(doc))
          .toList();

      final uid = _uid;
      debugPrint('Polls loaded: ${polls.length}, uid=$uid');

      if (uid != null) {
        await _fetchUserVotes(polls.map((p) => p.id).toList());
      }

      if (mounted) {
        setState(() {
          _polls = polls;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Stream error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  /// Load the current user's vote for each poll (parallel reads).
  Future<void> _fetchUserVotes(List<String> pollIds) async {
    final uid = _uid;
    if (uid == null) return;

    final futures = pollIds.map((pollId) async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('polls')
            .doc(pollId)
            .collection('votes')
            .doc(uid)
            .get();
        if (doc.exists) {
          final idx = doc.data()?['optionIndex'];
          if (idx is int) _userVotes[pollId] = idx;
        }
      } catch (_) {}
    });

    await Future.wait(futures);
  }

  // ── vote logic ───────────────────────────────────────────────────────────────

  Future<void> _castVote(String pollId, int newOptionIndex) async {
    final uid = _uid;

    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to vote.')),
        );
      }
      return;
    }

    if (_votingInProgress[pollId] == true) return;

    final previousVote = _userVotes[pollId];
    if (previousVote == newOptionIndex) return;

    setState(() {
      _votingInProgress[pollId] = true;
      _userVotes[pollId] = newOptionIndex;
    });

    try {
      final db = FirebaseFirestore.instance;
      final pollRef = db.collection('polls').doc(pollId);
      final voteRef = pollRef.collection('votes').doc(uid);

      // Step 1: read current poll data
      final snap = await pollRef.get();
      if (!snap.exists) throw Exception('Poll document not found: $pollId');

      final data = snap.data()!;
      debugPrint('Poll read OK, uid=$uid');

      final rawOptions = (data['options'] as List<dynamic>)
          .map((o) => Map<String, dynamic>.from(o as Map))
          .toList();

      // Normalise voteCount strings → int
      for (final opt in rawOptions) {
        final v = opt['voteCount'];
        opt['voteCount'] = v is int ? v : (int.tryParse(v.toString()) ?? 0);
      }

      // Decrement previous
      if (previousVote != null && previousVote < rawOptions.length) {
        final cur = rawOptions[previousVote]['voteCount'] as int;
        rawOptions[previousVote]['voteCount'] = (cur - 1).clamp(0, 9999999);
      }

      // Increment new
      if (newOptionIndex < rawOptions.length) {
        final cur = rawOptions[newOptionIndex]['voteCount'] as int;
        rawOptions[newOptionIndex]['voteCount'] = cur + 1;
      }



      // Step 2: write vote doc
      await voteRef.set({
        'optionIndex': newOptionIndex,
        'votedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Vote doc written OK');

      // Step 3: update poll counts
      await pollRef.update({'options': rawOptions});
      debugPrint('Poll counts updated OK');

    } catch (e, stack) {



      // Roll back optimistic update
      if (mounted) {
        setState(() {
          if (previousVote != null) {
            _userVotes[pollId] = previousVote;
          } else {
            _userVotes.remove(pollId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vote failed: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _votingInProgress.remove(pollId));
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isAdmin) {
      return AdminCommunityScreen(
        favoriteEvents: widget.favoriteEvents,
        addedEvents: widget.addedEvents,
        onToggleFavorite: widget.onToggleFavorite,
        onAddToCalendar: widget.onAddToCalendar,
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFCF3232),
        elevation: 0,
        title: const Text(
          "Community",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
        ),centerTitle: true,
    /*    leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupProfileScreen(
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
        ],*/
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFCF3232)))
          : _polls.isEmpty
              ? const Center(child: Text('No polls yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _polls.length,
                  itemBuilder: (context, index) =>
                      _buildPollCard(context, _polls[index], index),
                ),
    );
  }

  // ── poll card ────────────────────────────────────────────────────────────────

  Widget _buildPollCard(
      BuildContext context, CommunityPoll poll, int pollIndex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final userVote = _userVotes[poll.id]; // null = not yet voted
    final isVoting = _votingInProgress[poll.id] == true;

    return Column(
      children: [
        if (pollIndex == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Today",
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13),
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
              // Poll image
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
                    // Title
                    Text(
                      poll.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface),
                    ),

                    const SizedBox(height: 12),

                    // Options
                    ...List.generate(poll.options.length, (optIndex) {
                      final option = poll.options[optIndex];
                      final isSelected = userVote == optIndex;
                      final label = String.fromCharCode(65 + optIndex);

                      return GestureDetector(
                        onTap: isVoting
                            ? null
                            : () => _castVote(poll.id, optIndex),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                  // Radio circle
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFCF3232)
                                            : colorScheme.onSurface
                                                .withOpacity(0.4),
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
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: colorScheme.onSurface)),
                                        const SizedBox(height: 2),
                                        Text(
                                          option.formattedVotes,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? const Color(0xFFCF3232)
                                                  : colorScheme.onSurface
                                                      .withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isVoting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFCF3232)),
                          )
                        else if (userVote != null)
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Color(0xFFCF3232)),
                              const SizedBox(width: 4),
                              Text("Voted",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.5))),
                            ],
                          )
                        else
                          Text("Tap an option to vote",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface
                                      .withOpacity(0.4))),
                        Text(
                          poll.timeAgo,
                          style: TextStyle(
                              color:
                                  colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12),
                        ),
                      ],
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
