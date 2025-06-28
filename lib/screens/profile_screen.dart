import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  // For editing profile information
  bool _isEditing = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // For notification toggles
  bool _emailNotifications = false;
  bool _pushNotifications = false;
  bool _careerUpdates = false;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    if (_isEditing) {
      // Save changes if any
      _saveProfileChanges();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfileChanges() async {
    if (_user == null) return;
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_user?.email == null) return;
    try {
      await _auth.sendPasswordResetEmail(email: _user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset link: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                // Set initial values for controllers if not editing
                if (!_isEditing) {
                  _firstNameController.text = userData['firstName'] ?? '';
                  _lastNameController.text = userData['lastName'] ?? '';
                }
                
                final fullName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(fullName, _user!.email ?? 'No email'),
                    const SizedBox(height: 24),
                    _buildProfileInfoCard(userData),
                    const SizedBox(height: 24),
                    _buildNotificationsCard(),
                    const SizedBox(height: 24),
                    _buildSecurityCard(),
                    const SizedBox(height: 32),
                     SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                        onPressed: () async {
                          await _auth.signOut();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           backgroundColor: Colors.white,
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
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: TextStyle(fontSize: 24, color: Theme.of(context).primaryColor)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(Map<String, dynamic> userData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit, size: 16),
                  label: Text(_isEditing ? 'Save' : 'Edit'),
                  onPressed: _toggleEditing,
                  style: OutlinedButton.styleFrom(
                     foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildTextField(label: 'First Name', controller: _firstNameController, enabled: _isEditing),
            const SizedBox(height: 16),
            _buildTextField(label: 'Last Name', controller: _lastNameController, enabled: _isEditing),
             const SizedBox(height: 16),
            _buildTextField(label: 'Email', controller: TextEditingController(text: _user!.email), enabled: false),

          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      elevation: 2,
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
  }

   Widget _buildSecurityCard() {
    return Card(
      elevation: 2,
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
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _sendPasswordReset,
            ),
             ListTile(
              title: const Text('Two-Factor Authentication'),
              trailing: const Icon(Icons.arrow_forward_ios),
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
