import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';
import 'package:swachhata_app/services/imgbb_service.dart'; // Make sure the path is correct

class EditAdminProfilePage extends StatefulWidget {
  final void Function(Locale)? setLocale;
  const EditAdminProfilePage({super.key, this.setLocale});

  @override
  State<EditAdminProfilePage> createState() => _EditAdminProfilePageState();
}

class _EditAdminProfilePageState extends State<EditAdminProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  final ImgBBService _imgbbService = ImgBBService();

  File? _imageFile;
  String? _imageUrl;
  String _selectedLanguage = 'en';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedLanguage = data['language'] ?? 'en';
        _imageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadToImgBB(File imageFile) async {
    try {
      return await _imgbbService.uploadImage(imageFile);
    } catch (e) {
      debugPrint("Error uploading to ImgBB: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      String? imageUrl = _imageUrl;

      // ✅ Upload to ImgBB if new image selected
      if (_imageFile != null) {
        imageUrl = await _uploadToImgBB(_imageFile!);
      }

      // ✅ Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'language': _selectedLanguage,
        'profileImageUrl': imageUrl,
      });

      // ✅ Update locale
      widget.setLocale?.call(Locale(_selectedLanguage));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF27AE60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    _selectedLanguage == 'kn'
                        ? "ಪ್ರೊಫೈಲ್ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ"
                        : "Profile updated successfully",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Error: $e",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          loc.editProfile,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.save_rounded, color: Colors.white, size: 20),
              onPressed: _isSaving ? null : _saveProfile,
            ),
          ),
        ],
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Saving Profile...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 👤 Profile Image Section
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Profile Picture",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 3,
                                  ),
                                  image: _imageFile != null
                                      ? DecorationImage(
                                          image: FileImage(_imageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : (_imageUrl != null &&
                                                _imageUrl!.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(_imageUrl!),
                                                fit: BoxFit.cover,
                                              )
                                            : null),
                                ),
                                child:
                                    (_imageFile == null &&
                                        (_imageUrl == null ||
                                            _imageUrl!.isEmpty))
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey.shade400,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF2C5F2D),
                                        Color(0xFF1E3A1E),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          TextButton(
                            onPressed: _pickImage,
                            child: Text(
                              "Change Photo",
                              style: TextStyle(
                                color: Color(0xFF2C5F2D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // 📝 Personal Information Section
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 20),

                          _buildTextField(
                            controller: _nameController,
                            label: loc.name,
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? loc.enterName : null,
                          ),
                          SizedBox(height: 16),

                          _buildTextField(
                            controller: _phoneController,
                            label: loc.phone,
                            icon: Icons.phone_iphone_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v!.isEmpty ? loc.enterPhone : null,
                          ),
                          SizedBox(height: 16),

                          _buildTextField(
                            controller: _bioController,
                            label: loc.bio,
                            icon: Icons.info_outline_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // 🌐 Language Preference Section
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Language Preference",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.language_rounded,
                                        color: Colors.orange.shade600,
                                        size: 22,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      loc.language,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                DropdownButton<String>(
                                  value: _selectedLanguage,
                                  underline: SizedBox(),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedLanguage = val);
                                    }
                                  },
                                  items: [
                                    DropdownMenuItem(
                                      value: 'en',
                                      child: Row(
                                        children: [
                                          Text('🇺🇸'),
                                          SizedBox(width: 8),
                                          Text(
                                            'English',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'kn',
                                      child: Row(
                                        children: [
                                          Text('🇮🇳'),
                                          SizedBox(width: 8),
                                          Text(
                                            'ಕನ್ನಡ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // 💾 Save Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2C5F2D).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isSaving ? "Saving..." : loc.save,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
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
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(right: 12),
          child: Icon(icon, color: Color(0xFF2C5F2D)),
        ),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2C5F2D), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
