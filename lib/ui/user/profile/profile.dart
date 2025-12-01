import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swachhata_app/providers/locale_provider.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';
import 'edit_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

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
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
      });
    }
  }

  void _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    _fetchUserData(); // Refresh after edit
  }

  Future<void> _updateLanguage(Locale locale) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'language': locale.languageCode,
    });

    context.read<LocaleProvider>().setLocale(locale);
    final loc = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale.languageCode == 'kn'
              ? loc.languageChangedKannada
              : loc.languageChangedEnglish,
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final loc = AppLocalizations.of(context)!;

    if (userData == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
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
        ),
      );
    }

    // Handle Timestamp safely
    String joinedDate = "N/A";
    if (userData!['createdAt'] != null) {
      if (userData!['createdAt'] is Timestamp) {
        joinedDate = (userData!['createdAt'] as Timestamp)
            .toDate()
            .toLocal()
            .toString()
            .split(' ')
            .first;
      } else if (userData!['createdAt'] is String) {
        joinedDate = DateTime.tryParse(userData!['createdAt']) != null
            ? DateTime.parse(
                userData!['createdAt'],
              ).toLocal().toString().split(' ').first
            : "N/A";
      }
    }

    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.myProfile,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
            tooltip: loc.editProfile,
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: ClipOval(
                      child:
                          userData!['profileImageUrl'] != null &&
                              userData!['profileImageUrl'].toString().isNotEmpty
                          ? Image.network(
                              userData!['profileImageUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData!['name'] ?? loc.unnamedUser,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData!['email'] ?? '',
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

            // Main Content Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Title
                  Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Your account details and preferences",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phone Info
                  _buildInfoTile(
                    icon: Icons.phone_rounded,
                    label: loc.phone,
                    value: userData!['phone'] ?? loc.notProvided,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // Address Info
                  _buildInfoTile(
                    icon: Icons.location_on_rounded,
                    label: loc.address,
                    value: userData!['address'] ?? loc.notProvided,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),

                  // Bio Info
                  _buildInfoTile(
                    icon: Icons.info_outline_rounded,
                    label: loc.bio,
                    value: userData!['bio'] ?? loc.noBio,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 32),

                  // Language Switcher
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF3D3D3D)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.language_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.language,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentLocale.languageCode == 'kn'
                                    ? "ಕನ್ನಡ (Kannada)"
                                    : "English",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<Locale>(
                            value: currentLocale,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(8),
                            iconEnabledColor: primaryColor,
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: primaryColor,
                            ),
                            onChanged: (locale) {
                              if (locale != null) _updateLanguage(locale);
                            },
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : Colors.white,
                            items: const [
                              DropdownMenuItem(
                                value: Locale('en'),
                                child: Text(
                                  "English",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              DropdownMenuItem(
                                value: Locale('kn'),
                                child: Text(
                                  "ಕನ್ನಡ",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Joined Date
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF3D3D3D)
                            : const Color(0xFFE0E0E0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.joinedOn,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                joinedDate,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Custom Info Tile ---
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
