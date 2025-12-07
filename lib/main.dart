import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:teampulse/viewmodels/dashboard_viewmodel.dart';

import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/chapter_viewmodel.dart';
import 'viewmodels/team_viewmodel.dart';
import 'viewmodels/meeting_viewmodel.dart';
import 'viewmodels/attendance_viewmodel.dart';
import 'views/splash/splash_screen.dart';
import 'utils/theme.dart';

void main() {
  // runZonedGuarded captures uncaught async errors during app lifetime
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Optional: set global error handler for Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        // Send to your logging solution here
        // e.g., crashlytics.recordFlutterError(details);
      };

      try {
        // Initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Initialize Hive
        await Hive.initFlutter();
        await LocalStorageService.init();

        // Initialize Notification Service (after Firebase init)
        // Note: if you use firebase_messaging background handler, ensure the top-level
        // background handler function is registered before calling FirebaseMessaging.onBackgroundMessage
        await NotificationService.instance.initialize();

        // Start app
        runApp(const MyApp());
      } catch (e, st) {
        // Initialization error
        debugPrint('Fatal initialization error: $e\n$st');
        // You may want to show a minimal error UI rather than crashing, for example:
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Initialization failed: $e')),
            ),
          ),
        );
      }
    },
    (error, stack) {
      // Global uncaught error handler
      debugPrint('Uncaught zone error: $error\n$stack');
      // Report to crash analytics if available
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ChapterViewModel()),
        ChangeNotifierProvider(create: (_) => TeamViewModel()),
        ChangeNotifierProvider(create: (_) => MeetingViewModel()),
        ChangeNotifierProvider(create: (_) => AttendanceViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
      ],
      child: MaterialApp(
        title: 'TeamPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
