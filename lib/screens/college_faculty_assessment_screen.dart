import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollegeFacultyAssessmentScreen extends StatefulWidget {
  const CollegeFacultyAssessmentScreen({super.key});

  @override
  State<CollegeFacultyAssessmentScreen> createState() => _CollegeFacultyAssessmentScreenState();
}

class _CollegeFacultyAssessmentScreenState extends State<CollegeFacultyAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  static const Map<String, String> _questionMap = {
    'science_interest': 'Are you interested in Science?',
    'math_good': 'Are you good at Mathematics?',
    'biology_enjoy': 'Do you enjoy Biology?',
    'physics_fascinated': 'Are you fascinated by Physics?',
    'coding_interest': 'Do you like Coding or working with computers?',
    'crafting_knack': 'Do you have a knack for Crafting or building things?',
    'english_proficient': 'Are you proficient in English?',
    'languages_interest': 'Are you interested in learning other Languages?',
    'drawing_interest': 'Do you enjoy Drawing or visual arts?',
    'economics_interest': 'Are you interested in Economics or how markets work?',
    'sociology_interest': 'Do you find Sociology or the study of society interesting?',
    'acting_interest': 'Do you enjoy Acting or drama?',
    'sports_interest': 'Are you interested in Sports?',
  };
  
  final Map<String, String?> _answers = { for (var key in _questionMap.keys) key : null };
  
  bool get _allQuestionsAnswered => _answers.values.every((answer) => answer != null);
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _predictMajor() async {
    if (!_allQuestionsAnswered) {
      _showSnackBar('Please answer all questions before submitting.', backgroundColor: Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    const String apiUrl = 'https://amrhamza1-major-predictor-app.hf.space/gradio_api/call/predict';
    final List<String> data = _questionMap.keys.map((key) => _answers[key]!).toList();

    try {
      final postResponse = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': data}),
      );

      if (postResponse.statusCode == 200) {
        final Map<String, dynamic> postResponseData = json.decode(postResponse.body);
        if (postResponseData.containsKey('event_id')) {
          final String eventId = postResponseData['event_id'];
          final String streamUrl = '$apiUrl/$eventId';
          final getResponse = await http.get(Uri.parse(streamUrl));

          if (getResponse.statusCode == 200) {
            final List<String> lines = LineSplitter.split(getResponse.body).toList();
            String? predictedMajor;
            bool foundCompleteEvent = false;

            for (final line in lines) {
              if (line.startsWith('event:') && line.substring(6).trim() == 'complete') {
                foundCompleteEvent = true;
              } else if (line.startsWith('data:')) {
                if (foundCompleteEvent) {
                  final dynamic decodedData = json.decode(line.substring(5).trim());
                  if (decodedData is List && decodedData.isNotEmpty) {
                    predictedMajor = decodedData[0].toString();
                    break;
                  }
                }
              }
            }

            if (predictedMajor != null) {
              final User? currentUser = _auth.currentUser;
              if (currentUser != null) {
                // --- Save prediction as a report and get the ID ---
                final newReport = await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('reports')
                    .add({
                  'predictedRole': predictedMajor, // Use a consistent field name
                  'predictionType': 'College-Based',
                  'timestamp': FieldValue.serverTimestamp(),
                  'answers': _answers.entries.map((e) => {'question': e.key, 'answer': e.value}).toList(),
                  'feedbackGiven': false,
                });
                
                // --- Navigate with the new report ID ---
                if (mounted) {
                  context.go('/college-faculty-report/${newReport.id}/${Uri.encodeComponent(predictedMajor)}');
                }
              }
            } else {
              _showSnackBar('Failed to get a valid major prediction.', backgroundColor: Colors.orange);
            }
          } else {
            _showSnackBar('API stream call failed: ${getResponse.statusCode}', backgroundColor: Colors.red);
          }
        } else {
          _showSnackBar('Failed to get event_id from API.', backgroundColor: Colors.orange);
        }
      } else {
        _showSnackBar('API initial call failed: ${postResponse.statusCode}', backgroundColor: Colors.red);
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset('assets/images/logo.png', height: 40, width: 120, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24.0),
              const Text('College Faculty Assessment', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8.0),
              const Text('Answer these questions to find a suitable college major.', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
              const SizedBox(height: 32.0),
              ..._questionMap.entries.map((entry) {
                return Column(
                  children: [
                    _buildQuestion(entry.value, entry.key),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.grey, thickness: 0.5)),
                  ],
                );
              }).toList(),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_allQuestionsAnswered && !_isLoading) ? _predictMajor : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Get My Major Prediction', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(String questionText, String answerKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Text(questionText, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Radio<String>(
              value: 'Yes',
              groupValue: _answers[answerKey],
              onChanged: (value) => setState(() => _answers[answerKey] = value),
              activeColor: Colors.green,
            ),
            const Text('Yes'),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'No',
              groupValue: _answers[answerKey],
              onChanged: (value) => setState(() => _answers[answerKey] = value),
              activeColor: Colors.green,
            ),
            const Text('No'),
          ],
        )
      ],
    );
  }
}
