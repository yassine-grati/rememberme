import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:research_package/research_package.dart';
import 'package:cognition_package/cognition_package.dart';
import 'package:research_package/ui.dart'; // Try this for RPLocalizations
import 'package:cognition_package/ui.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/doctor_registration_screen.dart';
import 'screens/patient_registration_screen.dart';
import 'screens/main_screen.dart';
import 'screens/doctor_main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cognitive_test_screen.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RememberMeApp());
}

class RememberMeApp extends StatelessWidget {
  const RememberMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remember me',
      theme: ThemeData(
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16.0),
          headlineSmall: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      localizationsDelegates: [
        RPLocalizations.delegate,
        CPLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/doctor-register': (context) => const DoctorRegistrationScreen(),
        '/patient-register': (context) => const PatientRegistrationScreen(),
        '/main': (context) => const MainScreen(),
        '/doctor-main': (context) => const DoctorMainScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/cognitive-test':
            (context) => const CognitiveTestScreen(), // Add this route
      },
    );
  }
}
