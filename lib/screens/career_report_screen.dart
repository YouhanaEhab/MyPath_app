import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mypath/data/role_descriptions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerReportScreen extends StatelessWidget {
  final String reportId;
  final String predictedRole;

  const CareerReportScreen({
    super.key,
    required this.reportId,
    required this.predictedRole,
  });

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? roleDetails = ROLE_DESCRIPTIONS[predictedRole];
    final user = FirebaseAuth.instance.currentUser;

    if (roleDetails == null) {
      return Scaffold(
          body: Center(child: Text('Error: Details not found for $predictedRole')));
    }
    
    final String description = roleDetails['description'] ?? 'No description available.';
    final List<String> keyStrengths = List<String>.from(roleDetails['key_strengths'] ?? []);
    final String jobAverageSalary = roleDetails['job_average_salary'] ?? 'N/A';
    final String jobOutlook = roleDetails['job_outlook'] ?? 'N/A';
    final String roadmapUrl = roleDetails['roadmap_url'] ?? '';
    final String jobOffersUrl = roleDetails['job_offers_url'] ?? '';
    final String careerPathText =
        'A typical career path for a $predictedRole involves continuous learning and specialization. Specific paths might include advancement to senior roles, team leadership, or architectural positions.';

    void handleBackNavigation() {
      // If there's a screen to pop back to (like History), do that.
      if (context.canPop()) {
        context.pop();
      } else {
        // Otherwise, it means we came from a quiz, so go to home.
        context.go('/home');
      }
    }

    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: handleBackNavigation, // Use the new handler
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24.0),
              const Text('Your Career Prediction', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
              const SizedBox(height: 8.0),
              const Text('Here\'s what we found for you!', style: TextStyle(fontSize: 16.0, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 32.0),
              
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.work_outline, size: 40, color: Colors.green),
                      ),
                      const SizedBox(height: 16.0),
                      Text(predictedRole, style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                      const SizedBox(height: 8.0),
                      Text(description, style: const TextStyle(fontSize: 16.0, color: Colors.black87), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              _buildInfoCard(
                title: 'Key Strengths',
                icon: Icons.trending_up,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: keyStrengths.map((strength) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8.0),
                        Expanded(child: Text(strength, style: const TextStyle(fontSize: 16.0))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20.0),

              _buildInfoCard(
                title: 'Career Path',
                icon: Icons.directions_walk,
                content: Text(careerPathText, style: const TextStyle(fontSize: 16.0)),
                actionUrl: roadmapUrl,
                actionText: 'View Roadmap',
              ),
              const SizedBox(height: 20.0),

              _buildInfoCard(
                title: 'Expected Salary',
                icon: Icons.monetization_on_outlined,
                content: Text(jobAverageSalary, style: const TextStyle(fontSize: 16.0)),
              ),
              const SizedBox(height: 20.0),

              _buildInfoCard(
                title: 'Job Outlook',
                icon: Icons.work_history_outlined,
                content: Text(jobOutlook, style: const TextStyle(fontSize: 16.0)),
                actionUrl: jobOffersUrl,
                actionText: 'View Job Offers',
              ),
              const SizedBox(height: 32.0),

              if (user != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('reports').doc(reportId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final bool feedbackGiven = snapshot.hasData && snapshot.data!.exists ? (snapshot.data!.get('feedbackGiven') ?? false) : false;

                    return feedbackGiven
                        ? const Card(
                            color: Colors.green,
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Thank you for your feedback!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/feedback/$reportId'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              ),
                              child: const Text('Give Feedback', style: TextStyle(fontSize: 18.0, color: Colors.white)),
                            ),
                          );
                  },
                ),
              const SizedBox(height: 10.0),
               SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Take Another Assessment', style: TextStyle(fontSize: 18.0, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget content, String? actionUrl, String? actionText}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade700),
                const SizedBox(width: 8.0),
                Text(title, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 12.0),
            content,
            if (actionUrl != null && actionUrl.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _launchUrl(actionUrl),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(actionText ?? 'Learn More'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
