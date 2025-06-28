import 'package:flutter/material.dart';
import 'package:mypath/screens/prediction_type_screen.dart';
import 'package:mypath/screens/career_prediction_method_screen.dart';
// Removed import for personality_assessment_screen.dart as it's no longer managed here
//mport 'package:mypath/screens/skills_input_screen_placeholder.dart';
// Removed skills_assessment_quiz_screen.dart import as it's no longer managed here

/// A custom navigator for the Home tab, allowing persistent BottomNavigationBar.
/// Screens pushed onto this navigator will keep the main BottomNavigationBar visible.
class HomeTabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const HomeTabNavigator({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            switch (settings.name) {
              case '/':
                return const PredictionTypeScreenContent();
              case '/career_prediction_method':
                return const CareerPredictionMethodScreenContent();
              // Removed '/personality_assessment' route from here
              default:
                return const Text('Error: Unknown route in HomeTabNavigator');
            }
          },
        );
      },
      initialRoute: '/',
    );
  }
}
