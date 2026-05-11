import 'package:eventmanagementapp/splashscreen.dart';
import 'package:eventmanagementapp/walkthrough.dart';
import 'package:eventmanagementapp/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // will add this next
import 'create account.dart';
import 'home.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load saved theme
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;

  // Theme controller
  final themeNotifier = ValueNotifier<ThemeMode>(
    isDark ? ThemeMode.dark : ThemeMode.light,
  );

  runApp(MyApp(themeNotifier: themeNotifier));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MyApp({
    super.key,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // Theme setup
            themeMode: currentMode,

            // Light Theme
            theme: ThemeData.light().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.light().textTheme,
              ),
            ),

            // Dark Theme
            darkTheme: ThemeData.dark().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),

            initialRoute: '/',

            routes: {
              '/': (context) => SplashScreen(),

              '/walkthrough': (context) =>
                  WalkthroughScreen(),

              '/login': (context) => LoginScreen(),

              '/home': (context) => HomeScreen(
                themeNotifier: themeNotifier,
              ),

              '/create': (context) => CreateScreen(),
            },
          );
        },
      ),
    );

  }
}