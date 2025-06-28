import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:mypath/screens/career_report_screen.dart'; // Import the new report screen
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

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

  bool get _allQuestionsAnswered {
    return _answers.values.every((answer) => answer != null);
  }

  bool _isLoading = false;

  // Firebase instances
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
    setState(() {
      _isLoading = true;
    });

    const String apiUrl = 'https://amrhamza1-role-predictor-app.hf.space/gradio_api/call/predict';
    final List<String> data = _answers.values.map((e) => e!).toList();

    try {
      final postResponse = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': data}),
      );

      print('API POST Response Status Code: ${postResponse.statusCode}');
      print('API POST Raw Response Body: ${postResponse.body}');

      if (postResponse.statusCode == 200) {
        final Map<String, dynamic> postResponseData = json.decode(postResponse.body);
        if (postResponseData.containsKey('event_id')) {
          final String eventId = postResponseData['event_id'];
          final String streamUrl = '$apiUrl/$eventId';

          final getResponse = await http.get(Uri.parse(streamUrl));

          print('API GET Response Status Code: ${getResponse.statusCode}');
          print('API GET Raw Response Body: ${getResponse.body}');

          if (getResponse.statusCode == 200) {
            final List<String> lines = LineSplitter.split(getResponse.body).toList();
            String? predictedRole;
            bool foundCompleteEvent = false;

            for (final line in lines) {
              if (line.startsWith('event:')) {
                final String eventType = line.substring(6).trim();
                if (eventType == 'complete') {
                  foundCompleteEvent = true;
                  print('Skills API: Received event: complete.');
                }
              } else if (line.startsWith('data:')) {
                final String jsonString = line.substring(5).trim();
                if (jsonString.isEmpty) continue;

                if (foundCompleteEvent) {
                  try {
                    final dynamic decodedData = json.decode(jsonString);
                    if (decodedData is List && decodedData.isNotEmpty) {
                      predictedRole = decodedData[0].toString();
                      print('Skills API: Successfully parsed prediction: $predictedRole');
                      break;
                    } else if (decodedData == null) {
                      print('Skills API: Decoded data is null from "data: null".');
                    }
                  } on FormatException catch (e) {
                    print('Skills API: FormatException on data line: $e, Content: "$jsonString"');
                  } catch (e) {
                    print('Skills API: Unhandled error processing data line: $e, Content: "$jsonString"');
                  }
                }
              }
            }

            if (predictedRole != null) {
              // --- Save to Firestore ---
              final User? currentUser = _auth.currentUser;
              if (currentUser != null) {
                final String userId = currentUser.uid;
                // Correctly initialize _appId using Dart's String.fromEnvironment
                const String appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');
                print('Attempting to save prediction for user: $userId under app ID: $appId');

                try {
                  await _firestore
                      .collection('artifacts')
                      .doc(appId)
                      .collection('users')
                      .doc(userId)
                      .collection('predictions')
                      .add({
                    'predictedRole': predictedRole,
                    'predictionType': 'Skills-Based',
                    'timestamp': FieldValue.serverTimestamp(),
                    'answers': _answers.entries.map((e) => {'question': e.key, 'answer': e.value}).toList(), // Save raw answers
                    'feedbackGiven': false, // Initialize feedback status
                  });
                  print('Prediction saved successfully to Firestore for user: $userId');
                } catch (e, stackTrace) {
                  print('ERROR: Failed to save prediction to Firestore: $e');
                  print('STACK TRACE: $stackTrace');
                  _showSnackBar('Failed to save prediction history.', backgroundColor: Colors.red);
                }
              } else {
                print('Firestore Save CANCELED: User not logged in, cannot save prediction.');
                _showSnackBar('Please log in to save your prediction history.', backgroundColor: Colors.orange);
              }
              // --- End Save to Firestore ---

              _showSnackBar('Skills Prediction: $predictedRole', backgroundColor: Colors.green);
              // Navigate to the CareerReportScreen on successful prediction by pushing on root navigator
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushReplacementNamed(
                  '/career_report',
                  arguments: predictedRole,
                );
              }
            } else {
              _showSnackBar('Failed to get a valid skills prediction.', backgroundColor: Colors.orange);
              print('Skills API: No valid prediction found in stream.');
            }
          } else {
            _showSnackBar('Skills API stream call failed: ${getResponse.statusCode}', backgroundColor: Colors.red);
            print('Skills API Stream Error: ${getResponse.statusCode} - ${getResponse.body}');
          }
        } else {
          _showSnackBar('Failed to get event_id from skills API.', backgroundColor: Colors.orange);
          print('Skills API POST (no event_id): $postResponseData');
        }
      } else {
        _showSnackBar('Skills API initial call failed: ${postResponse.statusCode}', backgroundColor: Colors.red);
        print('Skills API POST Error: ${postResponse.statusCode} - ${postResponse.body}');
      }
    } catch (e, stackTrace) {
      _showSnackBar('An unexpected error occurred during prediction: $e', backgroundColor: Colors.red);
      print('Overall Network/Processing Error: $e');
      print('STACK TRACE: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitQuiz() {
    if (_formKey.currentState!.validate()) {
      _predictCareer();
    } else {
      _showSnackBar('Please answer all questions before submitting.', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Custom Header with back button and logo
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      // This pops from the root navigator, returning to the CareerPredictionMethodScreen
                      Navigator.of(context).pop();
                    },
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

              const Text(
                'Skills Assessment',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Tell us about your skills and experience to predict your career path.',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
              const SizedBox(height: 32.0),

              // Questions
              _buildQuestion('Did you do webdev during college time ?', 'webdev', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Are you good at Data analysis ?', 'data_analysis', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Reading and writing skills', 'reading_writing_skills', ['poor', 'medium', 'excellent']),
              _buildDivider(),
              _buildQuestion('Are you a tech person ?', 'tech_person', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Were you in a non tech society ?', 'non_tech_society', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Are you good at coding ?', 'coding_good', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Have you developed mobile apps ?', 'mobile_apps_developed', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Are you good at communication ?', 'communication_good', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Do you have specialization in security ?', 'security_specialization', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Have you ever handled large databases ?', 'handled_databases', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Do you have knowledge of statistics and data science?', 'statistics_data_science', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Are you proficient in English ?', 'proficient_english', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Have you ever managed some event?', 'managed_event', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Do you write technical blogs ?', 'technical_blogs', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Are you into marketing ?', 'marketing_into', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Are you a ML expert ?', 'ml_expert', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Do you have a lot of connections ?', 'connections_lot', ['yes', 'no']),
              _buildDivider(),
              _buildQuestion('Have you ever built live project ?', 'built_live_project', ['yes', 'no']),
              const SizedBox(height: 20.0),

              // Buttons
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
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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

  Widget _buildQuestion(String questionText, String answerKey, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Text(questionText, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
        FormField<String>(
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: options.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _answers[answerKey],
                  onChanged: (String? newValue) {
                    setState(() {
                      _answers[answerKey] = newValue;
                      state.didChange(newValue);
                    });
                  },
                  activeColor: Colors.green,
                  dense: true,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(color: Colors.grey, thickness: 0.5),
    );
  }
}
