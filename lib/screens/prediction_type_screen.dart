import 'package:flutter/material.dart';
import 'package:mypath/screens/career_prediction_method_screen.dart'; // Still needed for navigation

// Renamed to PredictionTypeScreenContent as it's now just the content
class PredictionTypeScreenContent extends StatelessWidget {
  const PredictionTypeScreenContent({super.key}); // Changed class name

  void _onCareerPredictionTapped(BuildContext context) {
    // Navigate to the new CareerPredictionMethodScreen by pushing onto the ROOT navigator
    // This will make it a full-screen overlay, covering the BottomNavigationBar.
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CareerPredictionMethodScreenContent(), // Navigating to content widget
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      ),
    );
    print('Career Prediction box tapped!');
  }

  void _onCollegeFacultyPredictionTapped(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('College Faculty Prediction selected!')),
    );
    print('College Faculty Prediction box tapped!');
    // Example: Navigator.of(context).pushNamed('/college_faculty_prediction_details', rootNavigator: true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'What would you like to predict?',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Choose the type of prediction you\'re interested in',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32.0),

          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(), // Restored physics
              children: [
                // Career Prediction Box
                InkWell(
                  onTap: () => _onCareerPredictionTapped(context),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.work_outline, // Bag icon
                              size: 40,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Career Prediction',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Discover your ideal career path based on your personality and skills',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0), // Spacing between cards

                // College Faculty Prediction Box
                InkWell(
                  onTap: () => _onCollegeFacultyPredictionTapped(context),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.school_outlined, // Graduation cap icon
                              size: 40,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'College Faculty Prediction',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Find the best faculty or major that matches your interests',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Added SizedBox for bottom spacing, which works with NeverScrollableScrollPhysics
          SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 20.0),
        ],
      ),
    );
  }
}
