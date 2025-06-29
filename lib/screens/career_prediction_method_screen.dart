import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CareerPredictionMethodScreenContent extends StatelessWidget {
  const CareerPredictionMethodScreenContent({super.key});

  void _onBasedOnPersonalityTapped(BuildContext context) {
    context.push('/personality-assessment');
  }

  void _onBasedOnSkillsTapped(BuildContext context) {
    context.push('/skills-assessment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.pop();
          },
        ),
        title: Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 90,
            //width: 90,
            fit: BoxFit.contain,
          ),
        ),
        actions: const [
          SizedBox(width: 48),
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
                physics: const NeverScrollableScrollPhysics(),
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
                  const SizedBox(height: 20.0),
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
          ],
        ),
      ),
    );
  }
}
