import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _userName = 'User';
  Map<String, dynamic>? _latestPrediction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        _userName = userDoc.data()?['firstName'] ?? 'User';
      }

      final reportSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (mounted && reportSnapshot.docs.isNotEmpty) {
        _latestPrediction = reportSnapshot.docs.first.data();
        _latestPrediction!['id'] = reportSnapshot.docs.first.id;
      }
    }
     finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.green.shade700),
            const SizedBox(width: 10),
            const Text('Exit MyPath?'),
          ],
        ),
        content: const Text('Are you sure you want to close the program?'),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('No', style: TextStyle(color: Colors.green)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            child: const Text('Yes, Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false; 
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldExit = await _showExitConfirmationDialog();
        if (shouldExit) {
          SystemNavigator.pop(); 
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Image.asset('assets/images/logo.png', height: 90),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false 
         
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchUserData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildWelcomeHeader(context),
                    const SizedBox(height: 24),
                    _buildHowItWorksCard(),
                    const SizedBox(height: 24),
                    _buildLatestPredictionCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Welcome, $_userName!',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Ready to discover your path? Let's get started.",
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              'Start a New Prediction',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      color: const Color(0xFF222831),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How It Works', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildStep('1. Choose Your Path:', 'Select whether you want to predict a career or a college major.'),
            const SizedBox(height: 12),
            _buildStep('2. Answer Questions:', 'Complete a short questionnaire based on your chosen method.'),
            const SizedBox(height: 12),
            _buildStep('3. Get Your Report:', 'Receive your personalized prediction with detailed insights.'),
          ],
        ),
      ),
    );
  }

  // --- UPDATED LAYOUT FOR "HOW IT WORKS" STEPS ---
  Widget _buildStep(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4), // Add a small space between title and subtitle
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildLatestPredictionCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Latest Prediction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_latestPrediction != null)
              _buildPredictionDetails(context, _latestPrediction!)
            else
              const Center(
                  child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('You have no predictions yet.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionDetails(BuildContext context, Map<String, dynamic> prediction) {
    final String result = prediction['predictedRole'] ?? 'N/A';
    final String type = prediction['predictionType'] == 'College-Based' ? 'College Major' : 'Career Path';
    final String method = prediction['predictionType'] ?? 'N/A';
    final Timestamp? timestamp = prediction['timestamp'];
    final String date = timestamp != null ? DateFormat('MMMM dd, yyyy').format(timestamp.toDate()) : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(result, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 12),
        _buildDetailRow('Type:', type),
        _buildDetailRow('Method:', method),
        _buildDetailRow('Predicted on:', date),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              final reportId = prediction['id'];
              final isCollege = type == 'College Major';
              if (isCollege) {
                context.push('/college-faculty-report/$reportId/${Uri.encodeComponent(result)}');
              } else {
                context.push('/career-report/$reportId/${Uri.encodeComponent(result)}');
              }
            },
            child: const Text('View Full Report'),
          ),
        )
      ],
    );
  }
  
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
