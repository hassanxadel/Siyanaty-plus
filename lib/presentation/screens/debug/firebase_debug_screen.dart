import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/firebase_debug.dart';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text(
          'Firebase Debug',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.backgroundGreen,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Debug Tools',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Debug current state button
            ElevatedButton(
              onPressed: _isLoading ? null : _debugCurrentState,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Debug Current User State',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // List all users button
            ElevatedButton(
              onPressed: _isLoading ? null : _listAllUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'List All Authorized Users',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Create Missing Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Full name field
            TextFormField(
              controller: _fullNameController,
              style: const TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Orbitron',
                ),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.lightBackground),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Phone field
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                labelStyle: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Orbitron',
                ),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.lightBackground),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Create profile button
            ElevatedButton(
              onPressed: _isLoading ? null : _createMissingProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightBackground,
                foregroundColor: AppTheme.backgroundGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundGreen),
                  )
                : const Text(
                    'Create Missing Profile',
                    style: TextStyle(fontFamily: 'Orbitron'),
                  ),
            ),
            
            const SizedBox(height: 24),
            
            // Delete user button (danger)
            ElevatedButton(
              onPressed: _isLoading ? null : _deleteCurrentUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Delete Current Firebase Auth User',
                style: TextStyle(fontFamily: 'Orbitron'),
              ),
            ),
            
            const Spacer(),
            
            const Text(
              'Note: Check console output for debug information',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkAccentGreen,
                fontFamily: 'Orbitron',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _debugCurrentState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseDebugUtils.debugCurrentUserState();
      _showMessage('Debug information logged to console');
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _listAllUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseDebugUtils.listAllAuthorizedUsers();
      _showMessage('User list logged to console');
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createMissingProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      _showMessage('Please enter a full name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseDebugUtils.createMissingUserProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
      );
      _showMessage('Missing profile created successfully');
      _fullNameController.clear();
      _phoneController.clear();
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteCurrentUser() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete the current Firebase Auth user? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseDebugUtils.deleteCurrentUser();
      _showMessage('Firebase Auth user deleted');
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
