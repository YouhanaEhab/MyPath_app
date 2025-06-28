import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For logout functionality
import 'package:mypath/screens/main_wrapper.dart'; // Import the new MainWrapper

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startJourney(BuildContext context) {
    // Navigate to the MainWrapper using push() instead of pushReplacementNamed()
    // This keeps HomeScreen on the stack, allowing a back navigation from MainWrapper.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
    print('Start Your Journey button pressed!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // MyPath Logo
              Image.asset(
                'assets/images/logo.png', // Ensure this path is correct
                height: 80,
                width: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32.0),

              // Welcome to Career Prediction text
              const Text(
                'Welcome to Career Prediction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16.0),

              // Discover your ideal career path... subtitle
              const Text(
                'Discover your ideal career path with our AI-powered prediction system. Get personalized insights based on your skills, interests, and goals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48.0),

              // Green Circular Icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade500, // Main green color
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.shade600, // Darker green inside
                    ),
                    child: const Icon(
                      Icons.work_outline, // Using a work-related icon
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48.0),

              // Start Your Journey Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startJourney(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // MyPath green
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Start Your Journey',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0), // Space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
