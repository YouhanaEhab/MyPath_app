import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mypath/screens/error_screen.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;
  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);

    // --- Global Error Handling ---
    // This catches errors within the Flutter framework (e.g., layout errors)
    FlutterError.onError = (details) {
      setState(() {
        _hasError = true;
        _errorMessage = 'A rendering error occurred. Please restart the app.';
      });
    };
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
     final isDeviceConnected = result.contains(ConnectivityResult.mobile) ||
                               result.contains(ConnectivityResult.wifi);
    setState(() {
      _isConnected = isDeviceConnected;
      if (!_isConnected) {
        _hasError = false; // Prioritize the 'no internet' message
      }
    });
  }
  
  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _checkInitialConnection();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ErrorScreen(
          errorType: ErrorType.noInternet,
          onRetry: _retry,
        ),
      );
    }

    if (_hasError) {
      return MaterialApp(
         debugShowCheckedModeBanner: false,
        home: ErrorScreen(
          errorType: ErrorType.generic,
          onRetry: _retry,
        ),
      );
    }

    // If connected and no errors, show the main app
    return widget.child;
  }
}
