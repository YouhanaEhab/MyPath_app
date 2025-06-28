import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalityAssessmentScreen extends StatefulWidget {
  const PersonalityAssessmentScreen({super.key});

  @override
  State<PersonalityAssessmentScreen> createState() => _PersonalityAssessmentScreenState();
}

class _PersonalityAssessmentScreenState extends State<PersonalityAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _opennessController = TextEditingController();
  final TextEditingController _conscientiousnessController = TextEditingController();
  final TextEditingController _extraversionController = TextEditingController();
  final TextEditingController _agreeablenessController = TextEditingController();
  final TextEditingController _neuroticismController = TextEditingController();
  // --- UPDATED TEST URL ---
  final String _oceanTestUrl = 'https://bigfive-test.com/';
  final FocusNode _opennessFocus = FocusNode();
  final FocusNode _conscientiousnessFocus = FocusNode();
  final FocusNode _extraversionFocus = FocusNode();
  final FocusNode _agreeablenessFocus = FocusNode();
  final FocusNode _neuroticismFocus = FocusNode();
  bool _isLoading = false;
  String? _collectiveValidationError;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _collectiveValidationError = _validateAllScores();
    });
  }

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

  String? _scoreValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final int? score = int.tryParse(value);
    if (score == null || score < 0 || score > 100) {
      return '0-100';
    }
    return null;
  }

  String? _validateAllScores() {
    if (_opennessController.text.isEmpty ||
        _conscientiousnessController.text.isEmpty ||
        _extraversionController.text.isEmpty ||
        _agreeablenessController.text.isEmpty ||
        _neuroticismController.text.isEmpty) {
      return null;
    }

    final List<int> scores = [
      int.tryParse(_opennessController.text) ?? -1,
      int.tryParse(_conscientiousnessController.text) ?? -1,
      int.tryParse(_extraversionController.text) ?? -1,
      int.tryParse(_agreeablenessController.text) ?? -1,
      int.tryParse(_neuroticismController.text) ?? -1,
    ];

    if (scores.any((score) => score < 0 || score > 100)) {
      return null;
    }

    final bool allZeros = scores.every((score) => score == 0);
    final bool allHundreds = scores.every((score) => score == 100);

    if (allZeros) return 'Scores cannot all be 0.';
    if (allHundreds) return 'Scores cannot all be 100.';
    return null;
  }

  bool get _allScoresFilledAndValid {
    bool allFieldsFilled = _opennessController.text.isNotEmpty &&
        _conscientiousnessController.text.isNotEmpty &&
        _extraversionController.text.isNotEmpty &&
        _agreeablenessController.text.isNotEmpty &&
        _neuroticismController.text.isNotEmpty;
    if (!allFieldsFilled) return false;
    bool individualFieldsPassRange = _scoreValidator(_opennessController.text) == null &&
        _scoreValidator(_conscientiousnessController.text) == null &&
        _scoreValidator(_extraversionController.text) == null &&
        _scoreValidator(_agreeablenessController.text) == null &&
        _scoreValidator(_neuroticismController.text) == null;
    if (!individualFieldsPassRange) return false;
    return _validateAllScores() == null;
  }

  void _submitScores() {
    _formKey.currentState!.validate();
    if (!_allScoresFilledAndValid) {
      _showSnackBar(_collectiveValidationError ?? 'Please ensure all scores are filled and valid.', backgroundColor: Colors.red);
      return;
    }
    _predictCareerFromScores();
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(_oceanTestUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not launch $_oceanTestUrl', backgroundColor: Colors.red);
    }
  }

  Future<void> _predictCareerFromScores() async {
    setState(() => _isLoading = true);

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
                  'predictionType': 'Personality-Based',
                  'timestamp': FieldValue.serverTimestamp(),
                  'scores': scoresAsStrings,
                  'feedbackGiven': false,
                });
                
                if (mounted) {
                  context.go('/career-report/${newReport.id}/${Uri.encodeComponent(predictedRole)}');
                }
              }
            } else {
              _showSnackBar('Failed to get a valid personality prediction.', backgroundColor: Colors.orange);
            }
          } else {
            _showSnackBar('Personality API stream call failed: ${getResponse.statusCode}', backgroundColor: Colors.red);
          }
        } else {
          _showSnackBar('Failed to get event_id from personality API.', backgroundColor: Colors.orange);
        }
      } else {
        _showSnackBar('Personality API initial call failed: ${postResponse.statusCode}', backgroundColor: Colors.red);
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
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
              const Text('Personality Assessment', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8.0),
              // --- UPDATED DESCRIPTION TEXT ---
              const Text(
                "Enter your Big Five personality scores (0-100). If you haven't taken the test, we recommend this one:", 
                style: TextStyle(fontSize: 16.0, color: Colors.grey)
              ),
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 180,
                  child: OutlinedButton.icon(
                    onPressed: _launchUrl,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      side: BorderSide(color: Colors.green.shade400, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      foregroundColor: Colors.green.shade700,
                    ),
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Take Personality Test', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              if (_collectiveValidationError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(_collectiveValidationError!, style: const TextStyle(color: Colors.red, fontSize: 14.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              _buildScoreInputField('Openness (O)', 'Enter score for Openness', _opennessController, focusNode: _opennessFocus, nextFocusNode: _conscientiousnessFocus, textInputAction: TextInputAction.next),
              const SizedBox(height: 20.0),
              _buildScoreInputField('Conscientiousness (C)', 'Enter score for Conscientiousness', _conscientiousnessController, focusNode: _conscientiousnessFocus, nextFocusNode: _extraversionFocus, textInputAction: TextInputAction.next),
              const SizedBox(height: 20.0),
              _buildScoreInputField('Extraversion (E)', 'Enter score for Extraversion', _extraversionController, focusNode: _extraversionFocus, nextFocusNode: _agreeablenessFocus, textInputAction: TextInputAction.next),
              const SizedBox(height: 20.0),
              _buildScoreInputField('Agreeableness (A)', 'Enter score for Agreeableness', _agreeablenessController, focusNode: _agreeablenessFocus, nextFocusNode: _neuroticismFocus, textInputAction: TextInputAction.next),
              const SizedBox(height: 20.0),
              _buildScoreInputField('Neuroticism (N)', 'Enter score for Neuroticism', _neuroticismController, focusNode: _neuroticismFocus, textInputAction: TextInputAction.done),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_allScoresFilledAndValid && !_isLoading) ? _submitScores : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Get Personality-Based Prediction', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white)),
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
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreInputField(String label, String hint, TextEditingController controller, {required FocusNode focusNode, FocusNode? nextFocusNode, TextInputAction? textInputAction}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction ?? TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          ),
          validator: _scoreValidator,
          onChanged: (value) => _updateButtonState(),
          onFieldSubmitted: (_) {
            final int? score = int.tryParse(controller.text);
            if (score == null || score < 0 || score > 100) {
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
