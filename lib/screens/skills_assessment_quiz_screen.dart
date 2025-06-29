import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SkillsAssessmentQuizScreen extends StatefulWidget {
  const SkillsAssessmentQuizScreen({super.key});

  @override
  State<SkillsAssessmentQuizScreen> createState() => _SkillsAssessmentQuizScreenState();
}

class _SkillsAssessmentQuizScreenState extends State<SkillsAssessmentQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _answers = {
    'webdev': null, 'data_analysis': null, 'reading_writing_skills': null,
    'tech_person': null, 'non_tech_society': null, 'coding_good': null,
    'mobile_apps_developed': null, 'communication_good': null,
    'security_specialization': null, 'handled_databases': null,
    'statistics_data_science': null, 'proficient_english': null,
    'managed_event': null, 'technical_blogs': null, 'marketing_into': null,
    'ml_expert': null, 'connections_lot': null, 'built_live_project': null,
  };
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

  Future<void> _predictCareer() async {
    setState(() => _isLoading = true);

    const String apiUrl = 'https://amrhamza1-role-predictor-app.hf.space/gradio_api/call/predict';
    final List<String> data = _answers.values.map((e) => e!).toList();

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
            String? predictedRole;
            bool foundCompleteEvent = false;

            for (final line in lines) {
              if (line.startsWith('event:') && line.substring(6).trim() == 'complete') {
                foundCompleteEvent = true;
              } else if (line.startsWith('data:')) {
                if (foundCompleteEvent) {
                  final dynamic decodedData = json.decode(line.substring(5).trim());
                  if (decodedData is List && decodedData.isNotEmpty) {
                    predictedRole = decodedData[0].toString();
                    break;
                  }
                }
              }
            }

            if (predictedRole != null) {
              final User? currentUser = _auth.currentUser;
              if (currentUser != null) {
                final newReport = await _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('reports')
                    .add({
                  'predictedRole': predictedRole,
                  'predictionType': 'Skills-Based',
                  'timestamp': FieldValue.serverTimestamp(),
                  'answers': _answers.entries.map((e) => {'question': e.key, 'answer': e.value}).toList(),
                  'feedbackGiven': false,
                });
                if (mounted) context.go('/career-report/${newReport.id}/${Uri.encodeComponent(predictedRole)}');
              }
            } else {
              _showSnackBar('Failed to get a valid skills prediction.', backgroundColor: Colors.orange);
            }
          } else {
            _showSnackBar('Skills API stream call failed: ${getResponse.statusCode}', backgroundColor: Colors.red);
          }
        } else {
          _showSnackBar('Failed to get event_id from skills API.', backgroundColor: Colors.orange);
        }
      } else {
        _showSnackBar('Skills API initial call failed: ${postResponse.statusCode}', backgroundColor: Colors.red);
      }
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitQuiz() {
    if (_formKey.currentState!.validate() && _allQuestionsAnswered) {
      _predictCareer();
    } else {
      _showSnackBar('Please answer all questions before submitting.', backgroundColor: Colors.red);
    }
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
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () => context.go('/main'),
          child: Image.asset('assets/images/logo.png', height: 90   , fit: BoxFit.contain,),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Skills Assessment', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8.0),
            const Text('Tell us about your skills and experience to predict your career path.', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
            const SizedBox(height: 32.0),
            ..._answers.keys.map((key) {
              final questionText = _getQuestionText(key);
              final options = _getOptions(key);
              return Column(
                children: [
                  _buildQuestion(questionText, key, options),
                  const Divider(thickness: 0.5),
                ],
              );
            }),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_allQuestionsAnswered && !_isLoading) ? _submitQuiz : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Get My Career Prediction', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white)),
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
    );
  }

  Widget _buildQuestion(String questionText, String answerKey, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(questionText, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 4),
          Row(
            children: options.map((option) {
              return Row(
                children: [
                  Radio<String>(
                    value: option,
                    groupValue: _answers[answerKey],
                    onChanged: (String? newValue) => setState(() => _answers[answerKey] = newValue),
                    activeColor: Colors.green,
                  ),
                  Text(option),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

 String _getQuestionText(String key) {
  const questions = {
    'webdev': 'Do you have knowledge about web development (e.g., HTML, CSS, JavaScript)?',
    'data_analysis': 'Do you know your way around data analysis?',
    'reading_writing_skills': 'How would you describe your reading and writing abilities?',
    'tech_person': 'Do you consider yourself a tech-savvy person?',
    'non_tech_society': 'Were you actively involved in any non-technical clubs or societies?',
    'coding_good': 'Are you confident in your coding and programming abilities?',
    'mobile_apps_developed': 'Have you ever developed a mobile application (for iOS or Android)?',
    'communication_good': 'Are youeffective at communicating your ideas to others?',
    'security_specialization': 'Do you have any knowledge in cybersecurity?',
    'handled_databases': 'Do you have experience managing or working with large databases?',
    'statistics_data_science': 'Are you familiar with the principles of statistics and data science?',
    'proficient_english': 'How proficient are you in the English language?',
    'managed_event': 'Have you ever taken a lead role in managing an event?',
    'technical_blogs': 'Do you enjoy writing or reading technical blogs and articles?',
    'marketing_into': 'Are you interested in the field of marketing and advertising?',
    'ml_expert': 'Do you have knowledge in Machine Learning (ML)?',
    'connections_lot': 'Do you have a strong professional network or many industry connections?',
    'built_live_project': 'Have you ever built and deployed a live project?',
  };
  return questions[key] ?? '';
}

  List<String> _getOptions(String key) {
    if (key == 'reading_writing_skills') return ['poor', 'medium', 'excellent'];
    return ['yes', 'no'];
  }
}
