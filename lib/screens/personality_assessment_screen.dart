import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For JSON encoding/decoding
//import 'package:mypath/screens/career_report_screen.dart'; // Import the new report screen
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class PersonalityAssessmentScreen extends StatefulWidget {
  const PersonalityAssessmentScreen({super.key});

  @override
  State<PersonalityAssessmentScreen> createState() => _PersonalityAssessmentScreenState();
}

class _PersonalityAssessmentScreenState extends State<PersonalityAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for each OCEAN score
  final TextEditingController _opennessController = TextEditingController();
  final TextEditingController _conscientiousnessController = TextEditingController();
  final TextEditingController _extraversionController = TextEditingController();
  final TextEditingController _agreeablenessController = TextEditingController();
  final TextEditingController _neuroticismController = TextEditingController();

  // URL for the external OCEAN test
  final String _oceanTestUrl = 'https://openpsychometrics.org/tests/IPIP-NEO-PI/'; // Example link

  // Add FocusNodes for each field
  final FocusNode _opennessFocus = FocusNode();
  final FocusNode _conscientiousnessFocus = FocusNode();
  final FocusNode _extraversionFocus = FocusNode();
  final FocusNode _agreeablenessFocus = FocusNode();
  final FocusNode _neuroticismFocus = FocusNode();

  bool _isLoading = false; // State for loading spinner
  String? _collectiveValidationError; // For displaying collective validation errors

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to re-evaluate validation and button state
    _opennessController.addListener(_updateButtonState);
    _conscientiousnessController.addListener(_updateButtonState);
    _extraversionController.addListener(_updateButtonState);
    _agreeablenessController.addListener(_updateButtonState);
    _neuroticismController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _opennessController.removeListener(_updateButtonState);
    _conscientiousnessController.removeListener(_updateButtonState);
    _extraversionController.removeListener(_updateButtonState);
    _agreeablenessController.removeListener(_updateButtonState);
    _neuroticismController.removeListener(_updateButtonState);

    _opennessController.dispose();
    _conscientiousnessController.dispose();
    _extraversionController.dispose();
    _agreeablenessController.dispose();
    _neuroticismController.dispose();

    _opennessFocus.dispose();
    _conscientiousnessFocus.dispose();
    _extraversionFocus.dispose();
    _agreeablenessFocus.dispose();
    _neuroticismFocus.dispose();

    super.dispose();
  }

  void _updateButtonState() {
    // This will trigger a rebuild to update the _allScoresFilledAndValid getter
    setState(() {
      _collectiveValidationError = _validateAllScores(); // Recalculate collective error
    });
  }

  // Helper function to show SnackBars
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

  // Validator for individual score fields (0-100 range only, no "Required")
  String? _scoreValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // No "Required" message, just return null
    }
    final int? score = int.tryParse(value);
    if (score == null || score < 0 || score > 100) {
      return '0-100'; // Keep concise
    }
    return null;
  }

  // Custom validation for all zeros or all hundreds
  String? _validateAllScores() {
    // Check if all fields are filled first (because parse returns -1 for empty, which would pass range check)
    if (_opennessController.text.isEmpty ||
        _conscientiousnessController.text.isEmpty ||
        _extraversionController.text.isEmpty ||
        _agreeablenessController.text.isEmpty ||
        _neuroticismController.text.isEmpty) {
      return null; // Don't show collective error if fields are empty, let button state handle it.
    }

    final List<int> scores = [
      int.tryParse(_opennessController.text) ?? -1, // Use -1 as sentinel for invalid parse
      int.tryParse(_conscientiousnessController.text) ?? -1,
      int.tryParse(_extraversionController.text) ?? -1,
      int.tryParse(_agreeablenessController.text) ?? -1,
      int.tryParse(_neuroticismController.text) ?? -1,
    ];

    // If any score is still invalid (e.g., non-numeric after isEmpty check), don't show collective error
    if (scores.any((score) => score < 0 || score > 100)) {
      return null;
    }

    final bool allZeros = scores.every((score) => score == 0);
    final bool allHundreds = scores.every((score) => score == 100);

    if (allZeros) {
      return 'Scores cannot all be 0.';
    }
    if (allHundreds) {
      return 'Scores cannot all be 100.';
    }
    return null;
  }

  bool get _allScoresFilledAndValid {
    // Check if all fields are filled
    bool allFieldsFilled = _opennessController.text.isNotEmpty &&
        _conscientiousnessController.text.isNotEmpty &&
        _extraversionController.text.isNotEmpty &&
        _agreeablenessController.text.isNotEmpty &&
        _neuroticismController.text.isNotEmpty;

    if (!allFieldsFilled) {
      return false;
    }

    // Check if all individual fields pass their 0-100 range validation
    bool individualFieldsPassRange = _scoreValidator(_opennessController.text) == null &&
        _scoreValidator(_conscientiousnessController.text) == null &&
        _scoreValidator(_extraversionController.text) == null &&
        _scoreValidator(_agreeablenessController.text) == null &&
        _scoreValidator(_neuroticismController.text) == null;

    if (!individualFieldsPassRange) {
      return false;
    }

    // Then check for the collective validation (all zeros/hundreds)
    return _validateAllScores() == null;
  }

  void _submitScores() {
    // The button's onPressed is already guarded by _allScoresFilledAndValid.
    // Calling validate here will just visually update any remaining errors.
    _formKey.currentState!.validate(); // Ensure all validators are run for visual feedback

    if (!_allScoresFilledAndValid) {
      // This case should ideally not be hit if the button is correctly disabled,
      // but serves as a safeguard.
      _showSnackBar(_collectiveValidationError ?? 'Please ensure all scores are filled and valid.', backgroundColor: Colors.red);
      return;
    }
    _predictCareerFromScores(); // Call the API
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(_oceanTestUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not launch $_oceanTestUrl', backgroundColor: Colors.red);
      throw Exception('Could not launch $_oceanTestUrl');
    }
  }

  Future<void> _predictCareerFromScores() async {
    setState(() {
      _isLoading = true;
    });

    const String apiUrl = 'https://amrhamza1-role-predictor-app-personality.hf.space/gradio_api/call/predict';
    final List<String> scoresAsStrings = [
      _opennessController.text,
      _conscientiousnessController.text,
      _extraversionController.text,
      _agreeablenessController.text,
      _neuroticismController.text,
    ];

    try {
      final postResponse = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': scoresAsStrings}),
      );

      print('Personality API POST Status: ${postResponse.statusCode}');
      print('Personality API POST Body: ${postResponse.body}');

      if (postResponse.statusCode == 200) {
        final Map<String, dynamic> postResponseData = json.decode(postResponse.body);
        if (postResponseData.containsKey('event_id')) {
          final String eventId = postResponseData['event_id'];
          final String streamUrl = '$apiUrl/$eventId';

          final getResponse = await http.get(Uri.parse(streamUrl));

          print('Personality API GET Status: ${getResponse.statusCode}');
          print('Personality API GET Body: ${getResponse.body}');

          if (getResponse.statusCode == 200) {
            final List<String> lines = LineSplitter.split(getResponse.body).toList();
            String? predictedRole;
            bool foundCompleteEvent = false;

            for (final line in lines) {
              if (line.startsWith('event:')) {
                final String eventType = line.substring(6).trim();
                if (eventType == 'complete') {
                  foundCompleteEvent = true;
                  print('Personality API: Received event: complete.');
                }
              } else if (line.startsWith('data:')) {
                final String jsonString = line.substring(5).trim();
                if (jsonString.isEmpty) continue;

                if (foundCompleteEvent) {
                  try {
                    final dynamic decodedData = json.decode(jsonString);
                    if (decodedData is List && decodedData.isNotEmpty) {
                      predictedRole = decodedData[0].toString();
                      print('Personality API: Successfully parsed prediction: $predictedRole');
                      break;
                    } else if (decodedData == null) {
                      print('Personality API: Decoded data is null from "data: null".');
                    }
                  } on FormatException catch (e) {
                    print('Personality API: FormatException on data line: $e, Content: "$jsonString"');
                  } catch (e) {
                    print('Personality API: Unhandled error processing data line: $e, Content: "$jsonString"');
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
                    'predictionType': 'Personality-Based',
                    'timestamp': FieldValue.serverTimestamp(),
                    'scores': scoresAsStrings, // Save the input scores as well
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

              _showSnackBar('Personality Prediction: $predictedRole', backgroundColor: Colors.green);
              // Navigate to the CareerReportScreen on successful prediction by pushing on root navigator
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushReplacementNamed(
                  '/career_report',
                  arguments: predictedRole,
                );
              }
            } else {
              _showSnackBar('Failed to get a valid personality prediction.', backgroundColor: Colors.orange);
              print('Personality API: No valid prediction found in stream.');
            }
          } else {
            _showSnackBar('Personality API stream call failed: ${getResponse.statusCode}', backgroundColor: Colors.red);
            print('Personality API Stream Error: ${getResponse.statusCode} - ${getResponse.body}');
          }
        } else {
          _showSnackBar('Failed to get event_id from personality API.', backgroundColor: Colors.orange);
          print('Personality API POST (no event_id): $postResponseData');
        }
      } else {
        _showSnackBar('Personality API initial call failed: ${postResponse.statusCode}', backgroundColor: Colors.red);
        print('Personality API POST Error: ${postResponse.statusCode} - ${postResponse.body}');
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction, // Keep for individual field feedback (0-100)
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
                        'assets/images/logo.png', // Ensure this path is correct
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

              const Text(
                'Personality Assessment',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Enter your OCEAN scores (0-100) or take an external test.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16.0), // Reduced spacing slightly

              // Take OCEAN Test Button (Moved to top, smaller)
              Align(
                alignment: Alignment.centerLeft, // Align left
                child: SizedBox(
                  width: 180, // Make it smaller
                  child: OutlinedButton.icon( // Use OutlinedButton.icon for icon + text
                    onPressed: _launchUrl,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      side: BorderSide(color: Colors.green.shade400, width: 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      foregroundColor: Colors.green.shade700, // Text color
                    ),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text(
                      'Take OCEAN Test',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32.0), // Spacing after the button

              // Display collective validation error if any
              if (_collectiveValidationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _collectiveValidationError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Openness Score Input
              _buildScoreInputField(
                'Openness (O)',
                'Enter score for Openness',
                _opennessController, 
                focusNode: _opennessFocus,
                nextFocusNode: _conscientiousnessFocus,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Conscientiousness Score Input
              _buildScoreInputField(
                'Conscientiousness (C)',
                'Enter score for Conscientiousness',
                _conscientiousnessController,
                focusNode: _conscientiousnessFocus,
                nextFocusNode: _extraversionFocus,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Extraversion Score Input
              _buildScoreInputField(
                'Extraversion (E)',
                'Enter score for Extraversion',
                _extraversionController,
                focusNode: _extraversionFocus,
                nextFocusNode: _agreeablenessFocus,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Agreeableness Score Input
              _buildScoreInputField(
                'Agreeableness (A)',
                'Enter score for Agreeableness',
                _agreeablenessController,
                focusNode: _agreeablenessFocus,
                nextFocusNode: _neuroticismFocus,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20.0),

              // Neuroticism Score Input
              _buildScoreInputField(
                'Neuroticism (N)',
                'Enter score for Neuroticism',
                _neuroticismController,
                focusNode: _neuroticismFocus, // Last field, no nextFocusNode
                textInputAction: TextInputAction.done, // Last field, so use done action
              ),
              const SizedBox(height: 32.0),

              // Get Prediction Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_allScoresFilledAndValid && !_isLoading) ? _submitScores : null, // Disabled until all valid and not loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Get Personality-Based Prediction',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10.0),

              // Back Button (Moved to bottom)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () { // Disabled during loading
                    // This pops from the root navigator, returning to the CareerPredictionMethodScreen
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0), // Spacing at bottom
            ],
          ),
        ),
      ),
    );
  }

  // Update _buildScoreInputField to support focus navigation
  Widget _buildScoreInputField(
      String label, String hint, TextEditingController controller,
      {required FocusNode focusNode, FocusNode? nextFocusNode, TextInputAction? textInputAction} ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction ?? TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.green, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          ),
          validator: _scoreValidator,
          onChanged: (value) {
            _updateButtonState();
          },
          onFieldSubmitted: (_) {
            // Prevent moving to next if value is not in 0-100
            final int? score = int.tryParse(controller.text);
            if (score == null || score < 0 || score > 100) {
              // Show error and keep focus
              FocusScope.of(context).requestFocus(focusNode);
              _showSnackBar('Please enter a valid score (0-100) before continuing.', backgroundColor: Colors.red);
            } else if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
