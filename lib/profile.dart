import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventmanagementapp/terms_conditions_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/events.dart';
import 'DynamicScreen.dart';
import 'editprofile.dart';
import 'help_support_screen.dart';
import 'notification screen.dart';

const String kUsernameKey = 'username';
const String kDarkModeKey = 'dark_mode';
String? _avatarUrl;

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;
  final List<Event> allEvents;
  final Set<Event> favoriteEvents;
  final Set<Event> addedEvents;
  final Function(Event) onToggleFavorite;
  final Function(Event) onAddToCalendar;

  const ProfileScreen({
    super.key,
    required this.themeModeNotifier,
    required this.allEvents,
    required this.favoriteEvents,
    required this.addedEvents,
    required this.onToggleFavorite,
    required this.onAddToCalendar,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Unnamed User';
  String _email = '';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadDarkMode(); // ADD THIS

  }
  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool(kDarkModeKey) ?? false;

    widget.themeModeNotifier.value =
    isDark ? ThemeMode.dark : ThemeMode.light;

    setState(() {});
  }
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final user = FirebaseAuth.instance.currentUser;

    String username = 'No Name';
    String? avatarUrl;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      username = data?['username'] ?? 'No Name';
      avatarUrl = data?['avatar']; // 👈 ADD THIS
    }

    setState(() {
      _username = username;
      _email = prefs.getString('user_email') ?? '';
      _avatarPath = prefs.getString('avatar_path');
      _avatarUrl = avatarUrl; // 👈 ADD THIS
    });
  }  bool get _isDarkMode =>
      widget.themeModeNotifier.value == ThemeMode.dark;

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kDarkModeKey, value);

    widget.themeModeNotifier.value =
    value ? ThemeMode.dark : ThemeMode.light;

    setState(() {});
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFCC2222)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  void _goToEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    if (updated == true) _loadPreferences();
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          allEvents: widget.allEvents,
          favoriteEvents: widget.favoriteEvents,
          addedEvents: widget.addedEvents,
          onToggleFavorite: widget.onToggleFavorite,
          onAddToCalendar: widget.onAddToCalendar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Setting',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avatar
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey[300],
                      backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                    : const AssetImage('assets/images/avatar.png')
                    as ImageProvider,
                    child: _avatarPath == null
                        ? const Icon(Icons.person,
                        size: 48, color: Colors.grey)
                        : null,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _username,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _email,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _goToEditProfile,
                    icon: const Icon(Icons.edit,
                        size: 16, color: Colors.white),
                    label: const Text('Edit Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCC2222),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  _MenuItem(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    isDark: isDark,
                    onTap: _goToNotifications,
                  ),

                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Privacy Policy',
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DynamicScreen(
                            docId: 'privacy_policy',
                          ),
                        ),
                      );
                    },
                  ),

                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const TermsConditionsScreen(),
                        ),
                      );
                    },
                  ),

                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),

                  _MenuItem(
                    icon: Icons.share_outlined,
                    label: 'Invite Your Friend',
                    isDark: isDark,
                    onTap: () {},
                  ),

                  _DarkModeRow(
                    isDarkMode: _isDarkMode,
                    isDark: isDark,
                    onChanged: _toggleDarkMode,
                  ),

                  _MenuItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    isDark: isDark,
                    labelColor: const Color(0xFFCC2222),
                    iconColor: const Color(0xFFCC2222),
                    onTap: _logout,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color? labelColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.labelColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? defaultColor),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? defaultColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: iconColor ?? Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

class _DarkModeRow extends StatelessWidget {
  final bool isDarkMode;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _DarkModeRow({
    required this.isDarkMode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.dark_mode,
        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        ),
      ),
      trailing: Switch(
        value: isDarkMode,
        onChanged: onChanged,
        activeColor: const Color(0xFFCC2222),
      ),
    );
  }
}