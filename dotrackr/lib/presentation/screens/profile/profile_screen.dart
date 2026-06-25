import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _instaController = TextEditingController();
  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(userProvider);
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _fullNameController.text = user.fullName ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _emailController.text = user.email ?? '';
      _addressController.text = user.address ?? '';
      _instaController.text = user.instagramHandle ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _instaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final hasImage = user?.profileImagePath != null && user!.profileImagePath!.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            )
          else
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          child: Column(
            children: [
              // Profile Image
              Stack(
                children: [
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                        image: _profileImage != null
                            ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                            : hasImage
                                ? DecorationImage(image: FileImage(File(user.profileImagePath!)), fit: BoxFit.cover)
                                : null,
                      ),
                      child: _profileImage == null && !hasImage
                          ? const Icon(Icons.person, size: 48, color: AppColors.textTertiary)
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: AppColors.backgroundPrimary),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Name display and Fields
              if (!_isEditing) ...[
                Text(
                  '${user?.pronoun ?? ''} ${user?.firstName ?? 'User'}'.trim(),
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                _buildInfoField('First Name', user?.firstName ?? 'Not set'),
                _buildInfoField('Full Name', user?.fullName ?? 'Not set'),
                _buildInfoField('Email', user?.email ?? 'Not set'),
                _buildInfoField('Age', user?.age?.toString() ?? 'Not set'),
                _buildAddressField('Address', user?.address ?? 'Not set'),
                _buildInfoField('Instagram', user?.instagramHandle ?? 'Not set'),
                _buildInfoField('Date of Birth', user?.dateOfBirth != null 
                    ? '${user!.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}' 
                    : 'Not set'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('Edit Profile'),
                  ),
                ),
              ] else ...[
                // Editable fields
                _buildEditableField('First Name', _firstNameController),
                _buildEditableField('Full Name', _fullNameController),
                _buildEditableField('Email', _emailController),
                _buildEditableField('Age', _ageController, keyboardType: TextInputType.number),
                _buildEditableAddressField('Address', _addressController),
                _buildEditableField('Instagram', _instaController),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Profile'),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value, 
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
            maxLines: 3,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableAddressField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your full address',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    final ageText = _ageController.text.trim();
    if (ageText.isNotEmpty) {
      final age = int.tryParse(ageText);
      if (age != null && (age < 1 || age > 150)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid age (1-150)')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(userProvider.notifier).updateProfile(
        firstName: _firstNameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        age: int.tryParse(ageText),
        email: email,
        profileImagePath: _profileImage?.path,
        address: _addressController.text.trim(),
        instagramHandle: _instaController.text.trim(),
      );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}