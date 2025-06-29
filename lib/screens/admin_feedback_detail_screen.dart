import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AdminFeedbackDetailScreen extends StatelessWidget {
  final String feedbackId;

  const AdminFeedbackDetailScreen({super.key, required this.feedbackId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('feedback').doc(feedbackId).get(),
        builder: (context, feedbackSnapshot) {
          if (feedbackSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!feedbackSnapshot.hasData || !feedbackSnapshot.data!.exists) {
            return const Center(child: Text('Feedback not found.'));
          }
          if (feedbackSnapshot.hasError) {
            return Center(child: Text('Error: ${feedbackSnapshot.error}'));
          }

          final feedback = feedbackSnapshot.data!.data() as Map<String, dynamic>;
          final reportId = feedback['reportId'] as String?;
          final userId = feedback['userId'] as String?;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- UPDATED: This card now fetches and displays user's full name ---
              _buildUserInfoCard(feedback),
              _buildFeedbackContentCard(feedback),
              if (reportId != null && userId != null)
                _buildReportDetails(reportId, userId),
              if (feedback['feedbackType'] == null) // Show for general feedback
                 _buildDetailCard('Feedback Type', [_buildDetailRow('Type:', 'General App Feedback')]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(Map<String, dynamic> feedback) {
    final userId = feedback['userId'] as String?;
    if (userId == null) {
      return _buildDetailCard('User Information', [
        _buildDetailRow('Name:', 'Unknown User'),
        _buildDetailRow('Email:', feedback['userEmail'] ?? 'N/A'),
      ]);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String fullName = 'Loading...';
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        } else if (userSnapshot.hasError || !userSnapshot.hasData) {
          fullName = 'User Not Found';
        }

        return _buildDetailCard('User Information', [
          _buildDetailRow('Name:', fullName),
          _buildDetailRow('Email:', feedback['userEmail'] ?? 'N/A'),
          _buildDetailRow('Submitted:', _formatTimestamp(feedback['timestamp'])),
        ]);
      },
    );
  }

  Widget _buildFeedbackContentCard(Map<String, dynamic> feedback) {
    return _buildDetailCard('User\'s Feedback', [
      RatingBarIndicator(
        rating: (feedback['rating'] as num?)?.toDouble() ?? 0.0,
        itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
        itemCount: 5,
        itemSize: 24.0,
      ),
      const SizedBox(height: 16),
      Text(feedback['feedbackText'] ?? 'No text provided.', style: const TextStyle(fontSize: 16, height: 1.5)),
    ]);
  }

  Widget _buildReportDetails(String reportId, String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).collection('reports').doc(reportId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildDetailCard('Associated Report', [const Center(child: CircularProgressIndicator())]);
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildDetailCard('Associated Report', [_buildDetailRow('Status:', 'Report not found or has been deleted by the user.')]);
        }
        final report = snapshot.data!.data() as Map<String, dynamic>;
        final answers = (report['answers'] as List<dynamic>?) ?? [];
        final scores = (report['scores'] as List<dynamic>?) ?? [];

        return _buildDetailCard('Original Assessment Details', [
          _buildDetailRow('Prediction Type:', report['predictionType'] ?? 'N/A'),
          _buildDetailRow('Predicted Result:', report['predictedRole'] ?? 'N/A'),
          const Divider(height: 24),
          const Text('User Answers:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (answers.isNotEmpty)
            ...answers.map((answer) {
              final question = (answer as Map)['question']?.toString() ?? '...';
              final answerText = answer['answer']?.toString() ?? '...';
              return _buildDetailRow('${_formatQuestion(question)}:', answerText);
            }).toList()
          else if (scores.isNotEmpty)
             ..._buildScores(scores)
          else 
            const Text("No answers were recorded for this report."),

        ]);
      },
    );
  }
  
  List<Widget> _buildScores(List<dynamic> scores) {
    final scoreNames = ['Openness', 'Conscientiousness', 'Extraversion', 'Agreeableness', 'Neuroticism'];
    List<Widget> scoreWidgets = [];
    for(int i = 0; i < scores.length; i++) {
      if (i < scoreNames.length) {
        scoreWidgets.add(_buildDetailRow('${scoreNames[i]}:', scores[i].toString()));
      }
    }
    return scoreWidgets;
  }
  
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM dd, yyyy  h:mm a').format(timestamp.toDate());
  }

  String _formatQuestion(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
