import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'pages/welcome_page.dart';
import 'pages/patient_dashboard.dart';
import 'pages/admin_page.dart';
import 'services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Set up notification action callback
  NotificationService.onActionCallback = (medicineId, time, action) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbService = DatabaseService(userId: user.uid);
    final status = action == 'taken' ? 'taken' : 'missed';
    await dbService.trackDose(medicineId, status, time);
  };

  // Initialize notifications in background (don't block app start)
  NotificationService().initialize().catchError((e) {
    debugPrint('Failed to initialize notifications: $e');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If snapshot has data, user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          if (authService.isAdmin(user.email ?? '')) {
            return const AdminPage();
          }
          return const PatientDashboard();
        }

        // Otherwise, show welcome page
        return const WelcomePage();
      },
    );
  }
}
