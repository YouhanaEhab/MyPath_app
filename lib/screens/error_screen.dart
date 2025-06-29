import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Enum to define the type of error to display
enum ErrorType { noInternet, generic }

class ErrorScreen extends StatelessWidget {
  final ErrorType errorType;
  final VoidCallback onRetry;

  const ErrorScreen({
    super.key,
    required this.errorType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
   
    final String animationAsset = 'assets/animations/error_animation.json';

    final String title = errorType == ErrorType.noInternet
        ? 'No Internet Connection'
        : 'Oops! Something Went Wrong';

    final String message = errorType == ErrorType.noInternet
        ? 'Please check your internet connection and try again.'
        : 'We encountered an unexpected error. Our team has been notified.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset( 
                animationAsset,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: const Color.fromARGB(255, 5, 6, 5),
                    side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
