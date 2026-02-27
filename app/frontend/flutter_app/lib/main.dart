import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_strings.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage _message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final langRaw = prefs.getString('app_language') ?? 'en';
  final themeRaw = prefs.getString('theme_mode') ?? ThemeMode.dark.name;

  final language = AppLanguage.values.firstWhere(
    (e) => e.name == langRaw,
    orElse: () => AppLanguage.en,
  );
  final themeMode = ThemeMode.values.firstWhere(
    (e) => e.name == themeRaw,
    orElse: () => ThemeMode.dark,
  );

  runApp(
    GigBitApp(
      initialToken: token,
      initialLanguage: language,
      initialThemeMode: themeMode,
    ),
  );
}
