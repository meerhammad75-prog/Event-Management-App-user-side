import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagementapp/profile.dart';
import 'package:eventmanagementapp/providers/auth_provider.dart';
import 'package:eventmanagementapp/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventmanagementapp/services/notification_service.dart';

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
  final NotificationService _notificationService = NotificationService();

  // Today's events — real-time stream from Firestore
  List<Event> _todayEvents = [];
  bool _eventsLoading = true;
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  // Favorites persisted in Firestore per user
  Set<Event> favoriteEvents = {};
  Set<Event> addedEvents = {};

  @override
  @override
  void initState() {
    super.initState();
    FcmService.saveToken(); // ← ADD

    _subscribeToTodayEvents();

    // Wait for auth to be ready before loading user data
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _loadFavorites();
      _loadAddedEvents();
    } else {
      // Auth not ready yet — listen for it
      FirebaseAuth.instance.authStateChanges().first.then((user) {
        if (user != null && mounted) {
          _loadFavorites();
          _loadAddedEvents();
        }
      });
    }
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
          category: data['category'] ?? 'Other',
          city: data['city'] ?? '',
          state: data['state'] ?? '',
          description: data['detail'] ?? '', // ← ADD

        );
      }).toList();

      if (mounted) {
        setState(() {
          _todayEvents = events;
          _eventsLoading = false;
        });

        // ← Auto-clean addedEvents when events change
        _removeStaleAddedEvents(events);
      }
    }, onError: (e) {
      debugPrint('Error streaming today events: $e');
      if (mounted) setState(() => _eventsLoading = false);
    });
  }

// Removes addedEvents that no longer exist in the events collection
  void _removeStaleAddedEvents(List<Event> currentEvents) {
    final existingTitles = currentEvents.map((e) => e.title).toSet();

    final stale = addedEvents
        .where((e) => !existingTitles.contains(e.title))
        .toList();

    if (stale.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      for (final e in stale) {
        addedEvents.remove(e);
      }
    });

    // Clean up Firestore and cancel notifications in background
    if (uid != null) {
      final batch = FirebaseFirestore.instance.batch();
      for (final e in stale) {
        final docId = e.title.replaceAll(RegExp(r'[^\w]'), '_');
        batch.delete(FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('addedEvents')
            .doc(docId));
        NotificationService.cancelReminder(e.title.hashCode);
      }
      batch.commit();
    }
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

  void _addToCalendar(Event event) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🗓️ _addToCalendar called for ${event.title}, uid=$uid');
    if (uid == null) return;

    setState(() => addedEvents.add(event));

    final docId = '${event.title}_${event.startTime.millisecondsSinceEpoch}'
        .replaceAll(RegExp(r'[^\w]'), '_');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addedEvents')
          .doc(docId)
          .set({
        'title': event.title,
        'location': event.location,
        'startTime': Timestamp.fromDate(event.startTime),
        'endTime': Timestamp.fromDate(event.endTime),
        'imageUrl': event.imageUrl,
        'category': event.category,
        'city': event.city,
        'state': event.state,
      });
    } catch (e) {
      debugPrint('Error saving added event: $e');
    }

    NotificationService.scheduleAndTrack(
      id: event.hashCode,
      title: event.title,
      eventTime: event.startTime,
      instance: _notificationService,
      uid: uid,
    );
  }  Future<void> _toggleDarkMode() async {
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
          onSwitchTab: (index) => setState(() => _selectedIndex = index), // ← ADD

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
Future<void> _loadAddedEvents() async {
final uid = FirebaseAuth.instance.currentUser?.uid;
if (uid == null) return;

try {
// Step 1 — get all saved added events for this user
final snapshot = await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('addedEvents')
.get();

if (snapshot.docs.isEmpty) return;

// Step 2 — get all currently existing event IDs from Firestore
final eventsSnapshot = await FirebaseFirestore.instance
.collection('events')
.get();

final existingTitles = eventsSnapshot.docs
.map((doc) => doc.data()['title'] as String? ?? '')
.toSet();

// Step 3 — filter out deleted events and clean up Firestore
final validEvents = <Event>{};
final batch = FirebaseFirestore.instance.batch();
bool hasDeletions = false;

for (final doc in snapshot.docs) {
final data = doc.data();
final title = data['title'] ?? '';

if (existingTitles.contains(title)) {
// Event still exists — keep it
validEvents.add(Event(
title: title,
location: data['location'] ?? '',
startTime: (data['startTime'] as Timestamp).toDate(),
endTime: (data['endTime'] as Timestamp).toDate(),
imageUrl: data['imageUrl'] ?? 'assets/images/eventimage.png',
category: data['category'] ?? 'Other',
city: data['city'] ?? '',
state: data['state'] ?? '',
));
} else {
// Event was deleted — remove from user's addedEvents and cancel notification
batch.delete(doc.reference);
NotificationService.cancelReminder(
'${title}_${(data['startTime'] as Timestamp).millisecondsSinceEpoch}'.hashCode,
);
hasDeletions = true;
}
}

// Step 4 — commit deletions if any
if (hasDeletions) await batch.commit();

if (mounted) setState(() => addedEvents = validEvents);
} catch (e) {
debugPrint('Error loading added events: $e');
}}}
