import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

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

  String? _emailError;
  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _passwordInputError;
  String? _confirmPasswordInputError;

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

      _emailError = _validateEmailContent(_emailController.text);
      _firstNameError = _validateFirstNameContent(_firstNameController.text);
      _lastNameError = _validateLastNameContent(_lastNameController.text);
      _usernameError = _validateUsernameContent(_usernameController.text);
      _passwordInputError = _validatePasswordStrength(_passwordController.text);
      _confirmPasswordInputError = _validateConfirmPasswordMatch(_confirmPasswordController.text);
    });

    if (_emailError != null ||
        _firstNameError != null ||
        _lastNameError != null ||
        _usernameError != null ||
        _passwordInputError != null ||
        _confirmPasswordInputError != null) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Please correct the errors in the form.', backgroundColor: Colors.red);
      return;
    }

    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseAuth.instance.signOut();
      // --- Updated Firestore Path ---
      final String userId = userCredential.user!.uid;
      
      // Correct path for saving user profile data according to new rules
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Set user details in the correct document
      await userDocRef.set({
        'uid': userId,
        'email': _emailController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign the user out immediately to force them to log in.
      
      
      _showSnackBar('Account created successfully! Please sign in.', backgroundColor: Colors.green);

      if (mounted) {
        // Pop the signup screen to return to the login screen.
        context.pop();
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
      _showSnackBar(message, backgroundColor: Colors.red);
    } catch (e) {
      _showSnackBar('An unexpected error occurred while creating your account. Please try again. Error: $e', backgroundColor: Colors.red);
    } finally {
        if(mounted){
           setState(() {
            _isLoading = false;
          });
        }
    }
  }

  void _navigateToSignIn() {
    context.pop();
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
            context.pop();
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
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Join MyPath and discover your career potential',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32.0),
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
                    errorText: _emailError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _emailError = _validateEmailContent(value);
                    });
                  },
                ),
                const SizedBox(height: 20.0),
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
                    errorText: _firstNameError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _firstNameError = _validateFirstNameContent(value);
                    });
                  },
                ),
                const SizedBox(height: 20.0),
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
                    errorText: _lastNameError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _lastNameError = _validateLastNameContent(value);
                    });
                  },
                ),
                const SizedBox(height: 20.0),
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
                    errorText: _usernameError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _usernameError = _validateUsernameContent(value);
                    });
                  },
                ),
                const SizedBox(height: 20.0),
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
                    errorText: _passwordInputError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _passwordInputError = _validatePasswordStrength(value);
                      _confirmPasswordInputError = _validateConfirmPasswordMatch(_confirmPasswordController.text);
                    });
                  },
                ),
                const SizedBox(height: 20.0),
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
                    errorText: _confirmPasswordInputError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _confirmPasswordInputError = _validateConfirmPasswordMatch(value);
                    });
                  },
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
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
                      onPressed: _isLoading ? null : _navigateToSignIn,
                      child: const Text(
                        'Sign in here',
                        style: TextStyle(
                          color: Colors.green,
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
