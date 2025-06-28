import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class FeedbackScreen extends StatefulWidget {
  final String? reportId; 
  const FeedbackScreen({super.key, this.reportId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate() || _rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide your feedback and a rating.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit feedback.')),
      );
      return;
    }

    try {
      String? reportPredictionType;
      // If this is feedback for a specific report, fetch the report's type first.
      if (widget.reportId != null) {
        final reportDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reports')
            .doc(widget.reportId)
            .get();
        if (reportDoc.exists) {
          // Get the predictionType from the original report
          reportPredictionType = reportDoc.data()?['predictionType'];
        }
      }

      // 1. Add feedback to the root-level 'feedback' collection
      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user.uid,
        'userEmail': user.email,
        if (widget.reportId != null) 'reportId': widget.reportId,
        'rating': _rating,
        'feedbackText': _feedbackController.text,
        'timestamp': FieldValue.serverTimestamp(),
        // Save the correct feedbackType based on the report or if it's general
        'feedbackType': reportPredictionType,
      });

      // 2. Only update the report if the feedback is for a specific report
      if (widget.reportId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reports')
            .doc(widget.reportId)
            .update({'feedbackGiven': true});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green),
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Your Feedback Matters', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Show a different prompt based on whether it's general or specific feedback
                widget.reportId != null 
                    ? 'What did you think about your prediction?'
                    : 'What did you think about our app?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts about your experience, and any suggestions for improvement...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your feedback.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Rate your overall experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Feedback', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
