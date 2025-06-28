import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PredictionTypeScreenContent extends StatelessWidget {
  const PredictionTypeScreenContent({super.key});

  void _onCareerPredictionTapped(BuildContext context) {
    context.push('/career-prediction-method');
  }

  void _onCollegeFacultyPredictionTapped(BuildContext context) {
    context.push('/college-faculty-assessment');
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Wrapped with PopScope ---
    return PopScope(
      canPop: false, // We will handle the pop action manually
      onPopInvoked: (didPop) {
        if (didPop) return;
        // When back is pressed, go to the main welcome screen
        context.go('/main');
      },
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'What would you like to predict?',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Choose the type of prediction you\'re interested in',
              style: TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
            const SizedBox(height: 32.0),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPredictionCard(
                    context: context,
                    title: 'Career Prediction',
                    subtitle: 'Discover your ideal career path based on your personality and skills',
                    icon: Icons.work_outline,
                    onTap: () => _onCareerPredictionTapped(context),
                  ),
                  const SizedBox(height: 20.0),
                  _buildPredictionCard(
                    context: context,
                    title: 'College Faculty Prediction',
                    subtitle: 'Find the best faculty or major that matches your interests',
                    icon: Icons.school_outlined,
                    onTap: () => _onCollegeFacultyPredictionTapped(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                child: Icon(icon, size: 40, color: Colors.green.shade700),
              ),
              const SizedBox(height: 16.0),
              Text(
                title,
                style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
