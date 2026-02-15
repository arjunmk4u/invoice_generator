import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final StorageService _storage = StorageService.instance;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _userNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _companyAddressController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _companyEmailController;
  late TextEditingController _gstNumberController;
  
  UserProfile? _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyAddressController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _companyEmailController = TextEditingController();
    _gstNumberController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _storage.getUserProfile();
      setState(() {
        _currentProfile = profile;
        _userNameController.text = profile.userName;
        _companyNameController.text = profile.companyName ?? '';
        _companyAddressController.text = profile.companyAddress ?? '';
        _companyPhoneController.text = profile.companyPhone ?? '';
        _companyEmailController.text = profile.companyEmail ?? '';
        _gstNumberController.text = profile.gstNumber ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedProfile = UserProfile(
        id: _currentProfile?.id,
        userName: _userNameController.text,
        companyName: _companyNameController.text,
        companyAddress: _companyAddressController.text,
        companyPhone: _companyPhoneController.text,
        companyEmail: _companyEmailController.text,
        gstNumber: _gstNumberController.text,
      );

      await _storage.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh home screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _gstNumberController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    const Text(
                      'PERSONAL INFORMATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _userNameController,
                      label: 'Your Name',
                      hint: 'Enter your name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Company Details Section
                    const Text(
                      'COMPANY DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      hint: 'Enter company name',
                      icon: Icons.business_outlined,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _companyAddressController,
                      label: 'Company Address',
                      hint: 'Enter company address',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _companyPhoneController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _companyEmailController,
                      label: 'Email Address',
                      hint: 'Enter email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _gstNumberController,
                      label: 'GST Number',
                      hint: 'Enter GST number (optional)',
                      icon: Icons.receipt_long_outlined,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
