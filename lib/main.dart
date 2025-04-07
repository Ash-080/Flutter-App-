import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_notification_service.dart';
import 'View/login_screen.dart';
import 'View/home_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseNotificationService.initialize();
  tz.initializeTimeZones();

  // ✅ Enable Firestore Persistence (Only for non-web platforms)
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(), // Determines whether to show Login or Home screen
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return snapshot.hasData ? const HomeScreen() : const LoginScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()), // Loading indicator
        );
      },
    );
  }
}
