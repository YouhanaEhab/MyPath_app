import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:mypath/data/role_descriptions.dart'; // To get role details
import 'package:mypath/screens/career_report_screen.dart'; // To view full report

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;
  String _currentFilter = 'All'; // 'All', 'Career-Based', 'College-Based'
  String _currentSort = 'newest'; // 'newest', 'oldest'

  late final String _appId; // Global variable for app ID

  @override
  void initState() {
    super.initState();
    // Correctly initialize _appId using Dart's String.fromEnvironment
    _appId = const String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');
    _fetchPredictions();
  }

  // Function to fetch predictions from Firestore
  void _fetchPredictions() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      print('User not logged in, cannot fetch history.');
      // Show a snackbar or message if not logged in
      _showSnackBar('Please log in to view your prediction history.', backgroundColor: Colors.orange);
      return;
    }

    final String userId = currentUser.uid;
    print('Fetching predictions for user: $userId under app ID: $_appId');

    Query predictionsQuery = _firestore
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('predictions');

    // Apply filter
    if (_currentFilter != 'All') {
      predictionsQuery = predictionsQuery.where('predictionType', isEqualTo: _currentFilter);
    }

    // Apply sorting (Firestore orderBy() is used here for direct sorting from DB)
    predictionsQuery = predictionsQuery.orderBy('timestamp', descending: _currentSort == 'newest');


    predictionsQuery.snapshots().listen((snapshot) {
      if (mounted) { // Ensure widget is still mounted before calling setState
        final fetchedPredictions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID for potential future use (e.g., deleting feedback)
          return data;
        }).toList();

        setState(() {
          _predictions = fetchedPredictions;
          _isLoading = false;
        });
        print('Fetched ${_predictions.length} predictions.');
      }
    }, onError: (error, stackTrace) {
      if (mounted) { // Ensure widget is still mounted before calling setState
        setState(() {
          _isLoading = false;
        });
        print('Error fetching predictions: $error');
        print('STACK TRACE: $stackTrace');
        _showSnackBar('Error loading prediction history. Please check console.', backgroundColor: Colors.red);
      }
    });
  }

  // Function to show SnackBar
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Image.asset(
                'assets/images/logo.png', // MyPath Logo
                height: 40,
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
            const Text(
              'Prediction History',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'View your past predictions and reports',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),

            // Sort and Filter Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentSort = _currentSort == 'newest' ? 'oldest' : 'newest';
                          _isLoading = true; // Show loading while re-fetching
                        });
                        _fetchPredictions();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      icon: Icon(_currentSort == 'newest' ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.grey),
                      label: Text('Sort: ${_currentSort == 'newest' ? 'Newest' : 'Oldest'}', style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Show filter options
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext bc) {
                            return SafeArea(
                              child: Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: const Icon(Icons.select_all),
                                    title: const Text('All Predictions'),
                                    onTap: () {
                                      setState(() {
                                        _currentFilter = 'All';
                                        _isLoading = true;
                                      });
                                      _fetchPredictions();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.work_outline),
                                    title: const Text('Career Prediction'),
                                    onTap: () {
                                      setState(() {
                                        _currentFilter = 'Career-Based';
                                        _isLoading = true;
                                      });
                                      _fetchPredictions();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.school_outlined),
                                    title: const Text('College Prediction'),
                                    onTap: () {
                                      setState(() {
                                        _currentFilter = 'College-Based';
                                        _isLoading = true;
                                      });
                                      _fetchPredictions();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      icon: const Icon(Icons.filter_list, color: Colors.grey),
                      label: Text('Filter: ${_currentFilter == 'Career-Based' ? 'Career' : (_currentFilter == 'College-Based' ? 'College' : 'All')}', style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Loading Indicator or Prediction List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green))
                  : _predictions.isEmpty
                      ? const Center(
                          child: Text(
                            'No predictions yet.\nComplete an assessment to see your history!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16.0, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: _predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _predictions[index];
                            final String predictedRole = prediction['predictedRole'] ?? 'Unknown Role';
                            final String predictionType = prediction['predictionType'] ?? 'N/A';
                            final Timestamp? timestamp = prediction['timestamp'] as Timestamp?;
                            final String formattedDate = timestamp != null
                                ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                                : 'N/A';

                            // You can add a 'feedbackGiven' field to your Firestore document
                            // For now, let's assume no feedback is given unless implemented
                            final bool hasFeedback = prediction['feedbackGiven'] ?? false; // Get feedback status from Firestore

                            // Determine icon based on prediction type
                            IconData cardIcon = Icons.work_outline; // Default career icon
                            if (predictionType == 'College-Based') {
                              cardIcon = Icons.school_outlined;
                            } else if (predictionType == 'Personality-Based' || predictionType == 'Skills-Based') {
                              cardIcon = Icons.work_outline;
                            }


                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to the full report screen
                                  Navigator.of(context).pushNamed(
                                    '/career_report',
                                    arguments: predictedRole, // Pass the predicted role to the report screen
                                  );
                                },
                                borderRadius: BorderRadius.circular(12.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(cardIcon, color: Colors.green.shade700),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            '${predictionType.replaceAll('-', ' ')}', // Format type for display
                                            style: const TextStyle(
                                                fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                          const Spacer(),
                                          if (hasFeedback)
                                            Row(
                                              children: [
                                                const Icon(Icons.check_circle, size: 18, color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text('Feedback', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                              ],
                                            )
                                          else
                                            Row(
                                              children: [
                                                const Icon(Icons.cancel_outlined, size: 18, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text('No Feedback', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8.0),
                                          Text(formattedDate, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                                          const SizedBox(width: 16.0),
                                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8.0),
                                          // Placeholder for user type (Personality-Based, Skills-Based)
                                          Text(predictionType, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 12.0),
                                      Text(
                                        'Result: $predictedRole',
                                        style: const TextStyle(
                                            fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          'Tap to view',
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
