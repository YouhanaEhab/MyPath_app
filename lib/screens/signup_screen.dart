import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  // Individual error state variables for each field
  String? _emailError;
  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _passwordInputError; // Renamed to avoid conflict with method
  String? _confirmPasswordInputError; // Renamed to avoid conflict with method

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  // Validation methods for each field (return error string or null)
  String? _validateEmailContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validateFirstNameContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your first name.';
    }
    return null;
  }

  String? _validateLastNameContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your last name.';
    }
    return null;
  }

  String? _validateUsernameContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please choose a username.';
    }
    return null;
  }

  // Password strength validation logic
  String? _validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one capital letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one small letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one symbol (!@#\$%^&*...).';
    }
    return null;
  }

  // Confirm password matching validation
  String? _validateConfirmPasswordMatch(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;

      // Manually trigger all validations to update error messages on submit attempt
      _emailError = _validateEmailContent(_emailController.text);
      _firstNameError = _validateFirstNameContent(_firstNameController.text);
      _lastNameError = _validateLastNameContent(_lastNameController.text);
      _usernameError = _validateUsernameContent(_usernameController.text);
      _passwordInputError = _validatePasswordStrength(_passwordController.text);
      _confirmPasswordInputError = _validateConfirmPasswordMatch(_confirmPasswordController.text);
    });

    // Check if any errors exist after manual validation
    if (_emailError != null ||
        _firstNameError != null ||
        _lastNameError != null ||
        _usernameError != null ||
        _passwordInputError != null ||
        _confirmPasswordInputError != null) {
      setState(() {
        _isLoading = false; // Hide spinner if validation fails
      });
      _showSnackBar('Please correct the errors in the form.', backgroundColor: Colors.red);
      return; // Stop if form is not valid
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Add user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Timestamp for when the user was created
      });

      // Clear input fields
      _emailController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Account created successfully!', backgroundColor: Colors.green);

      // Navigate to home screen or login screen after successful registration
      if (mounted) {
        Navigator.of(context).pop(); // Go back to Login screen
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email address is already in use by another account.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak. Please choose a stronger password.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred during registration: ${e.message}.';
          break;
      }
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(message, backgroundColor: Colors.red);
      print('Firebase Auth Error: ${e.code} - ${e.message}'); // For debugging
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('An unexpected error occurred. Please try again.', backgroundColor: Colors.red);
      print('General Error: $e'); // For debugging
    }
  }

  // Custom page transition for smoother navigation
  /*PageRouteBuilder _buildPageTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }*/

  void _navigateToSignIn() {
    Navigator.of(context).pop(); // Go back to Login screen
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
          onPressed: () {
            Navigator.of(context).pop(); // Go back to previous screen
          },
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled, // Disabled to control validation manually
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
                const SizedBox(height: 16.0), // Reduced spacing slightly for more fields

                // Join MyPath and discover your career potential
                const Text(
                  'Join MyPath and discover your career potential',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32.0),

                // Email Input Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _emailError, // Display error from state
                  ),
                  onChanged: (value) {
                    setState(() {
                      _emailError = _validateEmailContent(value);
                    });
                  },
                  validator: (value) => _validateEmailContent(value), // Still needed for _formKey.currentState!.validate()
                ),
                const SizedBox(height: 20.0),

                // First Name Input Field
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'Enter your first name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _firstNameError, // Display error from state
                  ),
                  onChanged: (value) {
                    setState(() {
                      _firstNameError = _validateFirstNameContent(value);
                    });
                  },
                  validator: (value) => _validateFirstNameContent(value), // Still needed for _formKey.currentState!.validate()
                ),
                const SizedBox(height: 20.0),

                // Last Name Input Field
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter your last name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _lastNameError, // Display error from state
                  ),
                  onChanged: (value) {
                    setState(() {
                      _lastNameError = _validateLastNameContent(value);
                    });
                  },
                  validator: (value) => _validateLastNameContent(value), // Still needed for _formKey.currentState!.validate()
                ),
                const SizedBox(height: 20.0),

                // Username Input Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Choose a username',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                    prefixIcon: const Icon(Icons.alternate_email, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _usernameError, // Display error from state
                  ),
                  onChanged: (value) {
                    setState(() {
                      _usernameError = _validateUsernameContent(value);
                    });
                  },
                  validator: (value) => _validateUsernameContent(value), // Still needed for _formKey.currentState!.validate()
                ),
                const SizedBox(height: 20.0),

                // Password Input Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Create a password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _passwordInputError, // Display error from state
                  ),
                  onChanged: (value) {
                    setState(() {
                      _passwordInputError = _validatePasswordStrength(value);
                      // Re-validate confirm password whenever main password changes
                      _confirmPasswordInputError = _validateConfirmPasswordMatch(_confirmPasswordController.text);
                    });
                  },
                  validator: (value) => _validatePasswordStrength(value), // Still needed for _formKey.currentState!.validate()
                ),
                const SizedBox(height: 20.0),

                // Confirm Password Input Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.green, width: 2.0)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
                    prefixIcon: const Icon(Icons.lock_reset, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                    errorText: _confirmPasswordInputError, // Display error from state
                  ),
                  onChanged: (value) {
                    setState(() {
                      _confirmPasswordInputError = _validateConfirmPasswordMatch(value);
                    });
                  },
                  validator: (value) => _validateConfirmPasswordMatch(value), // Still needed for _formKey.currentState!.validate()
                ),
                const SizedBox(height: 24.0),

                // Create Account Button with Loading Spinner
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp, // Disable button when loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // MyPath green
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // Already have an account? Sign in here
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _navigateToSignIn, // Disable when loading
                      child: const Text(
                        'Sign in here',
                        style: TextStyle(
                          color: Colors.green, // MyPath green
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
