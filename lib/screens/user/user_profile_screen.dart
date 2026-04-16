import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/pawmilya_palette.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isNameEditable = false;
  bool _isPhoneEditable = false;
  bool _isAddressEditable = false;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _auth.currentUser?.displayName ?? '');
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['realName'] ?? data['name'] ?? user.displayName ?? '';
          _phoneController.text = data['phoneNumber'] ?? data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isSaving = true; });

    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Update Auth Profile
        if (user.displayName != _nameController.text.trim()) {
          await user.updateDisplayName(_nameController.text.trim());
        }

        // Update Firestore Profile
        await _firestore.collection('users').doc(user.uid).set({
          'realName': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'email': user.email,
          'role': 'user', // Ensure role stays intact
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }

    setState(() { _isSaving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EA),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: PawmilyaPalette.textPrimary, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PawmilyaPalette.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar Placeholder
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: PawmilyaPalette.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: PawmilyaPalette.gold, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: PawmilyaPalette.goldDark,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email (Read Only)
                    _buildTextField(
                      label: 'Email Address',
                      controller: TextEditingController(text: _auth.currentUser?.email ?? ''),
                      icon: Icons.email_rounded,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    // Name
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      readOnly: !_isNameEditable,
                      suffixIcon: IconButton(
                        icon: Icon(_isNameEditable ? Icons.check : Icons.edit, color: PawmilyaPalette.gold),
                        onPressed: () {
                          setState(() {
                            _isNameEditable = !_isNameEditable;
                          });
                        },
                      ),
                      validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_rounded,
                      readOnly: !_isPhoneEditable,
                      suffixIcon: IconButton(
                        icon: Icon(_isPhoneEditable ? Icons.check : Icons.edit, color: PawmilyaPalette.gold),
                        onPressed: () {
                          setState(() {
                            _isPhoneEditable = !_isPhoneEditable;
                          });
                        },
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _buildTextField(
                      label: 'Address',
                      controller: _addressController,
                      icon: Icons.location_on_outlined,
                      readOnly: !_isAddressEditable,
                      suffixIcon: IconButton(
                        icon: Icon(_isAddressEditable ? Icons.check : Icons.edit, color: PawmilyaPalette.gold),
                        onPressed: () {
                          setState(() {
                            _isAddressEditable = !_isAddressEditable;
                          });
                        },
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PawmilyaPalette.gold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: PawmilyaPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: readOnly ? Colors.grey[600] : PawmilyaPalette.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: readOnly ? Colors.grey[400] : PawmilyaPalette.gold),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: PawmilyaPalette.gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}