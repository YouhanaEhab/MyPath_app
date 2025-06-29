import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
//import 'package:go_router/go_router.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  final _formKey = GlobalKey<FormState>(); // Key for the form
  bool _isEditing = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

 /* bool _emailNotifications = false;
  bool _pushNotifications = false;
  bool _careerUpdates = false;*/

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // --- NEW: Validation Functions ---
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    if (value.trim().length < 3) {
      return '$fieldName must be at least 3 characters.';
    }
    if (value.trim().length > 24) {
      return '$fieldName cannot exceed 24 characters.';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
      return '$fieldName can only contain letters.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required.';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (value.trim().length > 24) {
      return 'Username cannot exceed 24 characters.';
    }
    return null;
  }

  Future<String?> _showPasswordConfirmationDialog({String title = 'Confirm Identity', String content = 'To continue, please enter your password.'}) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleEditPressed() async {
    if (_user == null) return;
    
    final password = await _showPasswordConfirmationDialog(content: 'To edit your profile, please enter your password.');
    if (password == null || password.isEmpty) return;

    try {
      AuthCredential credential = EmailAuthProvider.credential(email: _user!.email!, password: password);
      await _user!.reauthenticateWithCredential(credential);

      if (mounted) setState(() => _isEditing = true);
    } on FirebaseAuthException catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.code == 'wrong-password' ? 'Incorrect password.' : e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSavePressed() async {
    if (_user == null) return;

    // First, validate the form fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors before saving.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final newUsername = _usernameController.text.trim();
    
    try {
      final usernameQuery = await _firestore.collection('users').where('username', isEqualTo: newUsername).limit(1).get();
      
      if (usernameQuery.docs.isNotEmpty && usernameQuery.docs.first.id != _user!.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This username is already taken. Please choose another.'), backgroundColor: Colors.red),
          );
        }
        // --- IMPORTANT: Do NOT exit edit mode if username is taken ---
        return; 
      }

      await _firestore.collection('users').doc(_user!.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': newUsername,
      });
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        setState(() => _isEditing = false); // Exit edit mode only on success
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleCancelPressed() {
    setState(() => _isEditing = false);
  }

  Future<void> _handleChangePasswordPressed() async {
     if (_user?.email == null) return;
    
    final password = await _showPasswordConfirmationDialog(title: 'Change Password', content: 'For security, please confirm your current password to receive a reset link.');
    if (password == null || password.isEmpty) return;

    try {
       AuthCredential credential = EmailAuthProvider.credential(email: _user!.email!, password: password);
      await _user!.reauthenticateWithCredential(credential);

      await _auth.sendPasswordResetEmail(email: _user!.email!);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email.'), backgroundColor: Colors.green),
        );
      }
    } on FirebaseAuthException catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.code == 'wrong-password' ? 'Incorrect password.' : e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSignOutPressed() async {
    final bool? confirmSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmSignOut == true) {
      await _auth.signOut();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _user == null
          ? const Center(child: Text("No user logged in."))
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Could not load user data."));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                if (!_isEditing) {
                  _firstNameController.text = userData['firstName'] ?? '';
                  _lastNameController.text = userData['lastName'] ?? '';
                  _usernameController.text = userData['username'] ?? '';
                }
                
                final fullName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(fullName, _user!.email ?? 'No email'),
                    const SizedBox(height: 24),
                    _buildProfileInfoCard(userData),
                    //const SizedBox(height: 24),
                    //_buildNotificationsCard(),
                    const SizedBox(height: 24),
                    _buildSecurityCard(),
                    const SizedBox(height: 32),
                     SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out', style: TextStyle(fontSize: 16)),
                        onPressed: _handleSignOutPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
  
  Widget _buildProfileHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 24, color: Colors.green)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(Map<String, dynamic> userData) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form( // Wrap fields in a Form
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (!_isEditing)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      onPressed: _handleEditPressed,
                      style: OutlinedButton.styleFrom(
                         foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _handleCancelPressed, child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save'),
                        onPressed: _handleSavePressed,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24),
              _buildTextField(label: 'First Name', controller: _firstNameController, enabled: _isEditing, validator: (val) => _validateName(val, 'First Name')),
              const SizedBox(height: 16),
              _buildTextField(label: 'Last Name', controller: _lastNameController, enabled: _isEditing, validator: (val) => _validateName(val, 'Last Name')),
              const SizedBox(height: 16),
              _buildTextField(label: 'Username', controller: _usernameController, enabled: _isEditing, validator: _validateUsername),
              const SizedBox(height: 16),
              _buildTextField(label: 'Email', controller: TextEditingController(text: _user!.email), enabled: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, bool enabled = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      inputFormatters: [LengthLimitingTextInputFormatter(24)], // Limit input length
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: Colors.grey.shade100,
        counterText: "", // Hide the counter
      ),
    );
  }

  /*Widget _buildNotificationsCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive updates via email'),
              value: _emailNotifications,
              onChanged: (val) => setState(() => _emailNotifications = val),
              activeColor: Colors.green,
            ),
             SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive push notifications'),
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
              activeColor: Colors.green,
            ),
             SwitchListTile(
              title: const Text('Career Updates'),
              subtitle: const Text('Get personalized career insights'),
              value: _careerUpdates,
              onChanged: (val) => setState(() => _careerUpdates = val),
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }*/

   Widget _buildSecurityCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
              onTap: _handleChangePasswordPressed,
            ),
             ListTile(
              title: const Text('Two-Factor Authentication'),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Two-Factor Authentication coming soon!')),
                  );
              },
            ),
          ],
        ),
      ),
    );
  }
}
