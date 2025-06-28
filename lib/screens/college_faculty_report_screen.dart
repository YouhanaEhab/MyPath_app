import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollegeFacultyReportScreen extends StatelessWidget {
  final String reportId;
  final String predictedMajor;

  const CollegeFacultyReportScreen({
    super.key, 
    required this.reportId,
    required this.predictedMajor
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
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
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: handleBackNavigation, // Use the new handler
          ),
          title: Image.asset('assets/images/logo.png', height: 40, width: 120),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  'Your Suggested College Major',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: [
                        const Icon(Icons.school_outlined, size: 50, color: Colors.green),
                        const SizedBox(height: 20),
                        Text(
                          predictedMajor,
                          style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This suggestion is based on your interests. We highly recommend researching specific university programs and curricula to find the perfect fit for you.',
                          style: TextStyle(fontSize: 16.0, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (user != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('reports').doc(reportId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final bool feedbackGiven = snapshot.data?.exists == true ? (snapshot.data!.get('feedbackGiven') ?? false) : false;

                      return feedbackGiven
                          ? const Card(
                              color: Colors.green,
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Thank you for your feedback!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: const Text(
                      'Take Another Assessment',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
