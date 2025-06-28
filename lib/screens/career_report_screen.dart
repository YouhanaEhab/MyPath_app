import 'package:flutter/material.dart';
import 'package:mypath/data/role_descriptions.dart'; // Import the data file
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

class CareerReportScreen extends StatelessWidget {
  final String predictedRole;

  const CareerReportScreen({super.key, required this.predictedRole});

  // Helper to launch URLs
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // You might want a SnackBar here for user feedback
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Look up the role details from the ROLE_DESCRIPTIONS map
    final Map<String, dynamic>? roleDetails = ROLE_DESCRIPTIONS[predictedRole];

    if (roleDetails == null) {
      // Handle case where predicted role is not found in your data
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header (Back button and Logo)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
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
                    const SizedBox(width: 48), // Placeholder for spacing
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              const Expanded(
                child: Center(
                  child: Text(
                    'Error: Career details not found for this role.',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate back to the main wrapper or home screen
                      Navigator.of(context).popUntil((route) => route.isFirst); // Go back to the very first route (HomeScreen/LoginScreen)
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Extract details
    final String description = roleDetails['description'] ?? 'No description available.';
    final List<String> keyStrengths = List<String>.from(roleDetails['key_strengths'] ?? []);
    final String jobAverageSalary = roleDetails['job_average_salary'] ?? 'N/A';
    final String jobOutlook = roleDetails['job_outlook'] ?? 'N/A';
    final String roadmapUrl = roleDetails['roadmap_url'] ?? '';
    final String jobOffersUrl = roleDetails['job_offers_url'] ?? '';

    // A simple career path text can be added if not explicitly in data
    // For now, let's keep it simple as "No detailed career path provided"
    // or you can derive it from the role if it's consistent.
    final String careerPathText = 'A typical career path for a ${predictedRole} involves continuous learning and specialization. Specific paths might include advancement to senior roles, team leadership, or architectural positions.';


    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Custom Header (Back button and Logo)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(), // Pop to previous screen (quiz)
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png', // MyPath Logo
                      height: 40,
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Placeholder for spacing
              ],
            ),
            const SizedBox(height: 24.0),

            // Your Career Prediction Header
            const Text(
              'Your Career Prediction',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Here\'s what we found for you!',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),

            // Predicted Role Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: Colors.green.shade50, // Light green background
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
                      child: const Icon(
                        Icons.work_outline, // Generic icon, replace if specific for roles
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      predictedRole,
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Your Key Strengths Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green.shade700),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Your Key Strengths',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    ...keyStrengths.map((strength) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.green.shade700),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  strength,
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Career Path Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_walk, color: Colors.green.shade700),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Career Path',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      careerPathText, // Using a generic path as per screenshot
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black87,
                      ),
                    ),
                    if (roadmapUrl.isNotEmpty) // Only show if URL exists
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _launchUrl(roadmapUrl),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View Roadmap'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Expected Salary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monetization_on_outlined, color: Colors.green.shade700),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Expected Salary',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      jobAverageSalary,
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Job Outlook Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_history_outlined, color: Colors.green.shade700),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Job Outlook',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      jobOutlook,
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.black87,
                      ),
                    ),
                    if (jobOffersUrl.isNotEmpty) // Only show if URL exists
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _launchUrl(jobOffersUrl),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View Job Offers'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32.0),

            // Give Feedback Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implement feedback logic (e.g., show a dialog, navigate to feedback form)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback feature coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Give Feedback',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10.0),

            // Take Another Assessment Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Pop all routes until main_wrapper, then possibly reset MainWrapper's state if needed
                  // For now, let's pop to the root of the MainWrapper (PredictionTypeScreenContent)
                 // Navigator.of(context).popUntil(ModalRoute.withName('/main_wrapper'));
                  // If you want to go all the way back to HomeScreen/LoginScreen:
                   Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Take Another Assessment',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
