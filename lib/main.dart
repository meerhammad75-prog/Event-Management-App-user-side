import 'package:eventmanagementapp/privacy_policy_screen.dart';
import 'package:eventmanagementapp/splashscreen.dart';
import 'package:eventmanagementapp/terms_conditions_screen.dart';
import 'package:eventmanagementapp/walkthrough.dart';
import 'package:eventmanagementapp/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'create account.dart';
import 'help_support_screen.dart';
import 'home.dart';
import 'login.dart';
import 'package:eventmanagementapp/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.notification?.title}');
}

void main() async {
  // Handle foreground messages — show local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('📩 Foreground message received: ${message.notification?.title}');

    await NotificationService.showForegroundNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
    );
  });
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permission
  await FirebaseMessaging.instance.requestPermission();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;

  final themeNotifier = ValueNotifier<ThemeMode>(
    isDark ? ThemeMode.dark : ThemeMode.light,
  );

  await NotificationService.init();

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
            themeMode: currentMode,
            theme: ThemeData.light().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.light().textTheme,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.dark().textTheme,
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => SplashScreen(),
              '/walkthrough': (context) => WalkthroughScreen(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(
                themeNotifier: themeNotifier,
              ),
              '/create': (context) => CreateScreen(),
              '/privacy_policy': (context) => PrivacyPolicyScreen(),
              '/terms_conditions': (context) => TermsConditionsScreen(),
              '/help_support': (context) => HelpSupportScreen(),
            },
          );
        },
      ),
    );
  }
}