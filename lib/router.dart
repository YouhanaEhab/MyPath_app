import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mypath/screens/login_screen.dart';
import 'package:mypath/screens/signup_screen.dart';
import 'package:mypath/screens/forgot_password_screen.dart';
import 'package:mypath/screens/main_wrapper.dart';
import 'package:mypath/screens/welcome_screen.dart';
import 'package:mypath/screens/prediction_type_screen.dart';
import 'package:mypath/screens/career_prediction_method_screen.dart';
import 'package:mypath/screens/skills_assessment_quiz_screen.dart';
import 'package:mypath/screens/personality_assessment_screen.dart';
import 'package:mypath/screens/career_report_screen.dart';
import 'package:mypath/screens/history_screen.dart';
import 'package:mypath/screens/profile_screen.dart';
import 'package:mypath/screens/feedback_screen.dart'; 
import 'package:mypath/screens/admin_feedback_screen.dart'; 
import 'package:mypath/screens/admin_feedback_detail_screen.dart';
import 'package:mypath/screens/college_faculty_assessment_screen.dart'; 
import 'package:mypath/screens/college_faculty_report_screen.dart'; 
import 'package:mypath/screens/splash_screen.dart'; // Import new screen
import 'package:mypath/auth_listenable.dart';

class FadeTransitionPage<T> extends Page<T> {
  final Widget child;

  const FadeTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}


final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/', // --- UPDATED: Start at the splash screen ---
  refreshListenable: AuthListenable(),
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isAtAuthPage = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot-password';
    
    // Allow the splash screen to show
    if (state.matchedLocation == '/') {
        return null;
    }

    if (!loggedIn) {
      return isAtAuthPage ? null : '/login';
    }
    
    if (isAtAuthPage) {
      return '/main';
    }
    return null;
  },
  routes: [
    // --- NEW: Route for the splash screen ---
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const WelcomeScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              builder: (BuildContext context, GoRouterState state) =>
                  const PredictionTypeScreenContent(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
             GoRoute(
              path: '/profile',
              builder: (BuildContext context, GoRouterState state) =>
                  const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
             GoRoute(
              path: '/history',
              builder: (BuildContext context, GoRouterState state) =>
                  const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/admin',
              builder: (BuildContext context, GoRouterState state) =>
                  const AdminFeedbackScreen(),
            ),
          ],
        ),
      ],
    ),
    
    GoRoute(
      path: '/prediction-type', 
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const PredictionTypeScreenContent(),
      ),
    ),
    GoRoute(
      path: '/admin/feedback-detail/:feedbackId',
      pageBuilder: (context, state) {
        final feedbackId = state.pathParameters['feedbackId']!;
        return FadeTransitionPage(
          key: state.pageKey,
          child: AdminFeedbackDetailScreen(feedbackId: feedbackId),
        );
      },
    ),
    GoRoute(
      path: '/feedback/:reportId',
      pageBuilder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return FadeTransitionPage(
          key: state.pageKey,
          child: FeedbackScreen(reportId: reportId),
        );
      },
    ),
    GoRoute(
      path: '/career-prediction-method',
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const CareerPredictionMethodScreenContent(),
      ),
    ),
    GoRoute(
      path: '/skills-assessment',
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const SkillsAssessmentQuizScreen(),
      ),
    ),
    GoRoute(
      path: '/personality-assessment',
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const PersonalityAssessmentScreen(),
      ),
    ),
    GoRoute(
      path: '/career-report/:reportId/:role',
      pageBuilder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        final role = state.pathParameters['role']!;
        return FadeTransitionPage(
          key: state.pageKey,
          child: CareerReportScreen(reportId: reportId, predictedRole: role),
        );
      },
    ),
    GoRoute(
      path: '/college-faculty-assessment',
      pageBuilder: (context, state) => FadeTransitionPage(
        key: state.pageKey,
        child: const CollegeFacultyAssessmentScreen(),
      ),
    ),
    GoRoute(
      path: '/college-faculty-report/:reportId/:major',
      pageBuilder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        final major = state.pathParameters['major']!;
        return FadeTransitionPage(
          key: state.pageKey,
          child: CollegeFacultyReportScreen(reportId: reportId, predictedMajor: major),
        );
      },
    ),
  ],
);
