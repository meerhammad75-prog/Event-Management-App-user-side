import 'package:eventmanagementapp/profile.dart';
import 'package:flutter/material.dart';
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

  final List<Event> homeEvents = [
    Event(
      title: "Tech Meetup",
      location: "2464 Royal Ln. Mesa, New Jersey 45463",
      startTime: DateTime(2026, 5, 5, 14, 0),
      endTime: DateTime(2026, 5, 5, 15, 0),
      imageUrl: "assets/images/ddp.png",
    ),
    Event(
      title: "AI Conference",
      location: "2464 Royal Ln. Mesa, New Jersey 45463",
      startTime: DateTime(2025, 11, 10, 10, 0),
      endTime: DateTime(2025, 11, 10, 13, 0),
      imageUrl: "https://i.pravatar.cc/150?img=5",
    ),
  ];

  Set<Event> favoriteEvents = {};
  Set<Event> addedEvents = {};

  void _toggleFavorite(Event event) {
    setState(() {
      if (favoriteEvents.contains(event)) {
        favoriteEvents.remove(event);
      } else {
        favoriteEvents.add(event);
      }
    });
  }

  void _addToCalendar(Event event) {
    setState(() {
      addedEvents.add(event);
    });
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

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return HomeTab(
          allEvents: homeEvents,
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
          featuredEvents: [
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
              startTime: DateTime(2025, 10, 28, 19, 0),
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
          ],
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
          allEvents: homeEvents,
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
      default:
        return HomeTab(
          allEvents: homeEvents,
          favoriteEvents: favoriteEvents,
          addedEvents: addedEvents,
          onToggleFavorite: _toggleFavorite,
          onAddToCalendar: _addToCalendar,
        );
    }
  }

  Widget _buildSettingsScreen() {
    final isDark = widget.themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDark,
            onChanged: (_) => _toggleDarkMode(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(),

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
              width: 24,
              height: 24,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? "assets/images/featurenavicon_selected.png"
                  : "assets/images/featurenavicon.png",
              width: 24,
              height: 24,
            ),
            label: "Features",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? "assets/images/communitynavicon_selected.png"
                  : "assets/images/communitynavicon.png",
              width: 24,
              height: 24,
            ),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 3
                  ? "assets/images/favrtnavicon_selected.png"
                  : "assets/images/favrtnavicon.png",
              width: 24,
              height: 24,
            ),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 4
                  ? "assets/images/settingnavicon_selected.png"
                  : "assets/images/settingnavicon.png",
              width: 24,
              height: 24,
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}