import 'package:flutter/material.dart';
import 'package:mypath/screens/personality_assessment_screen.dart'; // Import actual personality screen
import 'package:mypath/screens/skills_assessment_quiz_screen.dart'; // Import actual skills screen

// Renamed to CareerPredictionMethodScreenContent as it's now just the content
class CareerPredictionMethodScreenContent extends StatelessWidget {
  const CareerPredictionMethodScreenContent({super.key});

  void _onBasedOnPersonalityTapped(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Based on Personality selected!')),
    );
    print('Based on Personality box tapped!');
    // Navigate to PersonalityAssessmentScreen by pushing onto the ROOT navigator
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PersonalityAssessmentScreen(),
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
  }

  void _onBasedOnSkillsTapped(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Based on Skills selected!')),
    );
    print('Based on Skills box tapped!');
    // Navigate to SkillsAssessmentQuizScreen by pushing onto the ROOT navigator
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SkillsAssessmentQuizScreen(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // This Scaffold is needed if this screen is pushed as a new route
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton( // Back button remains as it's a "drill-down" screen
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // This pops from the current navigator (which is the root navigator here),
            // effectively going back to PredictionTypeScreenContent.
            Navigator.of(context).pop();
          },
        ),
        title: Center(
          child: Image.asset(
            'assets/images/logo.png', // Ensure this path is correct
            height: 40,
            width: 120,
            fit: BoxFit.contain,
          ),
        ),
        actions: const [
          SizedBox(width: 48), // Adjust as necessary
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'How would you like to predict your career?',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Choose your preferred method for career prediction',
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
                  // Based on Personality Box
                  InkWell(
                    onTap: () => _onBasedOnPersonalityTapped(context),
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
                                Icons.psychology_outlined, // Brain icon
                                size: 40,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            const Text(
                              'Based on Personality',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8.0),
                            const Text(
                              'Answer personality-based questions to find careers that match your traits',
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

                  // Based on Skills Box
                  InkWell(
                    onTap: () => _onBasedOnSkillsTapped(context),
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
                                Icons.track_changes_outlined, // Target icon
                                size: 40,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            const Text(
                              'Based on Skills',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8.0),
                            const Text(
                              'Describe your skills and abilities to get personalized career suggestions',
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
            // Added SizedBox for bottom spacing
            SizedBox(height: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 20.0),
          ],
        ),
      ),
    );
  }
}
