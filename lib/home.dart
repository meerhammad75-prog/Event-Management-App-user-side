import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagementapp/profile.dart';
import 'package:eventmanagementapp/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomeTab.dart';
import 'community.dart';
import 'favorite screen.dart';
import 'features.dart';
import 'model/events.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const HomeScreen({super.key, required this.themeNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Today's events — real-time stream from Firestore
  List<Event> _todayEvents = [];
  bool _eventsLoading = true;
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  // Favorites persisted in Firestore per user
  Set<Event> favoriteEvents = {};
  Set<Event> addedEvents = {};

  @override
  void initState() {
    super.initState();
    _subscribeToTodayEvents();
    _loadFavorites();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  // ── Subscribe to today's events in real time ──────────────────────────────
  void _subscribeToTodayEvents() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    _eventsSubscription = FirebaseFirestore.instance
        .collection('events')
        .where('startTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots()
        .listen((snapshot) {
      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Event(
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          imageUrl: data['imageUrl'] ?? 'assets/images/eventimage.png',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _todayEvents = events;
          _eventsLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error streaming today events: $e');
      if (mounted) setState(() => _eventsLoading = false);
    });
  }

  // ── Load favorites from Firestore for this user ───────────────────────────
  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();

      final favs = snapshot.docs.map((doc) {
        final data = doc.data();
        return Event(
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          imageUrl: data['imageUrl'] ?? 'assets/images/eventimage.png',
        );
      }).toSet();

      if (mounted) setState(() => favoriteEvents = favs);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  // ── Toggle favorite & sync to Firestore ──────────────────────────────────
  void _toggleFavorite(Event event) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites');

    setState(() {
      if (favoriteEvents.contains(event)) {
        favoriteEvents.remove(event);
      } else {
        favoriteEvents.add(event);
      }
    });

    final docId = '${event.title}_${event.startTime.millisecondsSinceEpoch}'
        .replaceAll(RegExp(r'[^\w]'), '_');

    try {
      if (favoriteEvents.contains(event)) {
        await favRef.doc(docId).set({
          'title': event.title,
          'location': event.location,
          'startTime': Timestamp.fromDate(event.startTime),
          'endTime': Timestamp.fromDate(event.endTime),
          'imageUrl': event.imageUrl,
        });
      } else {
        await favRef.doc(docId).delete();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  void _addToCalendar(Event event) {
    setState(() => addedEvents.add(event));
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (widget.themeNotifier.value == ThemeMode.dark) {
      widget.themeNotifier.value = ThemeMode.light;
      await prefs.setBool('dark_mode', false);
    } else {
      widget.themeNotifier.value = ThemeMode.dark;
      await prefs.setBool('dark_mode', true);
    }
  }

  Widget _getScreen(String role) {
    switch (_selectedIndex) {
      case 0:
        return HomeTab(
          allEvents: _todayEvents,
          isLoading: _eventsLoading,
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
      case 1:
        return FeaturesScreen(
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
      case 2:
        return CommunityScreen(
          role: role,
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
      case 3:
        return FavouriteScreen(
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
      case 4:
        return ProfileScreen(
          themeModeNotifier: widget.themeNotifier,
          allEvents: _todayEvents,
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
      default:
        return HomeTab(
          allEvents: _todayEvents,
          isLoading: _eventsLoading,
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

    return Scaffold(
      body: _getScreen(role),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFCF3232),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 0
                  ? "assets/images/homeicon_selected.png"
                  : "assets/images/homeicon.png",
              width: 24, height: 24,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? "assets/images/featurenavicon_selected.png"
                  : "assets/images/featurenavicon.png",
              width: 24, height: 24,
            ),
            label: "Features",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? "assets/images/communitynavicon_selected.png"
                  : "assets/images/communitynavicon.png",
              width: 24, height: 24,
            ),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 3
                  ? "assets/images/favrtnavicon_selected.png"
                  : "assets/images/favrtnavicon.png",
              width: 24, height: 24,
            ),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 4
                  ? "assets/images/settingnavicon_selected.png"
                  : "assets/images/settingnavicon.png",
              width: 24, height: 24,
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}