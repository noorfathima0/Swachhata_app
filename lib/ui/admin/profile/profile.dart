import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';
import 'package:swachhata_app/providers/locale_provider.dart';
import 'edit_profile.dart';

class AdminProfilePage extends StatefulWidget {
  final void Function(Locale)? setLocale; // from main.dart
  const AdminProfilePage({super.key, this.setLocale});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color _primaryColor = Color(0xFF2C5F2D);

  Map<String, dynamic>? adminData;
  bool isLoading = true;
  Locale _selectedLocale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      final langCode = data?['language'] ?? 'en';

      setState(() {
        adminData = data;
        _selectedLocale = Locale(langCode);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _showProfileDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Provider.of<LocaleProvider>(context, listen: false);

    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Loading Profile...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (adminData == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            loc.profile,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "⚠️ Admin data not found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please check your connection and try again",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final String name = adminData!['name'] ?? 'Admin';
    final String email = adminData!['email'] ?? '';
    final String phone = adminData!['phone'] ?? 'N/A';
    final String role = adminData!['role'] ?? 'Admin';
    final String bio = adminData!['bio'] ?? 'No bio added';
    final String? profileImage = adminData!['profileImageUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          loc.profile,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              tooltip: "Edit Profile",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditAdminProfilePage(setLocale: widget.setLocale),
                  ),
                );
                _fetchAdminData(); // Refresh after editing
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🧑‍💼 Profile Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (profileImage != null && profileImage.isNotEmpty) {
                        _showProfileDialog(profileImage);
                      }
                    },
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            image:
                                profileImage != null && profileImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(profileImage),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image: AssetImage(
                                      'assets/default_profile.png',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: _primaryColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 💼 Profile Info Cards
            _buildSectionTitle("Personal Information"),
            const SizedBox(height: 16),

            _buildInfoTile(
              Icons.phone_rounded,
              loc.phone,
              phone,
              Colors.blue.shade50,
              Colors.blue.shade600,
            ),
            _buildInfoTile(
              Icons.info_outline_rounded,
              loc.bio,
              bio,
              Colors.purple.shade50,
              Colors.purple.shade600,
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("App Preferences"),
            const SizedBox(height: 16),

            // Language Preference Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
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
                  title: Text(
                    "Language",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _selectedLocale.languageCode.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedLocale.languageCode == 'en' ? 'EN' : 'HI',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🚪 Logout Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.red.shade600, Colors.red.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: Text(
                  loc.logout,
                  style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () async {
                  await _auth.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📋 Helper UI Components
  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color iconBgColor,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            value,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
