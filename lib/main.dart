import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'package:mypath/screens/login_screen.dart';
import 'package:mypath/screens/signup_screen.dart';
import 'package:mypath/screens/forgot_password_screen.dart';
import 'package:mypath/screens/home_screen.dart'; // HomeScreen is now the content for the Home tab
import 'package:mypath/screens/main_wrapper.dart'; // Import MainWrapper (the top-level authenticated shell)
import 'package:mypath/screens/prediction_type_screen.dart';
import 'package:mypath/screens/career_prediction_method_screen.dart';
import 'package:mypath/screens/skills_assessment_quiz_screen.dart';
import 'package:mypath/screens/personality_assessment_screen.dart';
import 'package:mypath/screens/career_report_screen.dart';
import 'package:mypath/screens/history_screen.dart';


// Import your firebase_options.dart file after running flutterfire configure
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyPath',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const Wrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(), // Removed as HomeScreen is now primarily inside MainWrapper's tab
        '/main_wrapper': (context) => const MainWrapper(), // Main authenticated shell
        '/prediction_type': (context) => const PredictionTypeScreenContent(),
        '/career_prediction_method': (context) => const CareerPredictionMethodScreenContent(),
        '/skills_assessment_quiz_full_screen': (context) => const SkillsAssessmentQuizScreen(),
        '/personality_assessment_full_screen': (context) => const PersonalityAssessmentScreen(),
        '/career_report': (context) => CareerReportScreen( // Route that accepts arguments
              predictedRole: ModalRoute.of(context)!.settings.arguments as String,
            ),
        '/history': (context) => const HistoryScreen(), // New route for the HistoryScreen
      },
    );
  }
}

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          // If logged in, go directly to MainWrapper, which handles the tabs (including Home)
          return const MainWrapper();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
