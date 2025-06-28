import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

/// A change notifier that listens to Firebase auth state changes.
///
/// This is used with go_router's `refreshListenable` to automatically
/// redirect the user when their authentication state changes.
class AuthListenable extends ChangeNotifier {
  late final StreamSubscription<User?> _authStateSubscription;

  AuthListenable() {
    // Start listening to the auth state stream
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((_) {
      // When the auth state changes (login/logout), notify listeners.
      notifyListeners();
    });
  }

  @override
  void dispose() {
    // Clean up the subscription when the object is disposed.
    _authStateSubscription.cancel();
    super.dispose();
  }
}
