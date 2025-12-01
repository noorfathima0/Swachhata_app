import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swachhata_app/services/imgbb_service.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImgBBService _imgService = ImgBBService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _profileImageUrl;
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  // ✅ Pink theme colors matching the Profile dashboard box
  final Color primaryColor = const Color(0xFFE91E63);
  final Color primaryDark = const Color(0xFFC2185B);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
  );

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _selectedLanguage = data['language'] ?? 'en';
        _profileImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File imageFile = File(picked.path);
    setState(() => _isLoading = true);

    try {
      final url = await _imgService.uploadImage(imageFile);
      setState(() => _profileImageUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.success),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.error} $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    await _firestore.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'language': _selectedLanguage,
      'profileImageUrl': _profileImageUrl ?? '',
    });

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileUpdated),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.editProfile,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.loading,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Edit Profile",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Update your personal information",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF2D2D2D)
                            : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Profile Image
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: primaryColor.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child:
                                            _profileImageUrl != null &&
                                                _profileImageUrl!.isNotEmpty
                                            ? Image.network(
                                                _profileImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons.person_rounded,
                                                      color: primaryColor,
                                                      size: 40,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.person_rounded,
                                                color: primaryColor,
                                                size: 40,
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap to change photo",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),

                          // Name Field
                          _buildFormField(
                            controller: _nameController,
                            label: loc.name,
                            icon: Icons.person_rounded,
                            validator: (v) =>
                                v == null || v.isEmpty ? loc.enterName : null,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Bio Field
                          _buildFormField(
                            controller: _bioController,
                            label: loc.bio,
                            icon: Icons.info_outline_rounded,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Phone Field
                          _buildFormField(
                            controller: _phoneController,
                            label: loc.phone,
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Address Field
                          _buildFormField(
                            controller: _addressController,
                            label: loc.address,
                            icon: Icons.location_on_rounded,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 16),

                          // Language Dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF3D3D3D)
                                    : const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedLanguage,
                                decoration: InputDecoration(
                                  labelText: loc.language,
                                  labelStyle: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white60
                                        : Colors.black45,
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text(
                                      loc.english,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'kn',
                                    child: Text(
                                      loc.kannada,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedLanguage = v);
                                },
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF2D2D2D)
                                    : Colors.white,
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: primaryColor,
                                  size: 28,
                                ),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _saveProfile,
                              icon: const Icon(Icons.save_rounded, size: 24),
                              label: Text(
                                loc.save,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.black45,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
        ),
        validator: validator,
      ),
    );
  }
}
