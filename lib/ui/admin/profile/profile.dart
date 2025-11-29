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
  final Color _primaryColor = Colors.teal;

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
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    Provider.of<LocaleProvider>(context, listen: false);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (adminData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.profile)),
        body: const Center(child: Text("⚠️ Admin data not found")),
      );
    }

    final String name = adminData!['name'] ?? 'Admin';
    final String email = adminData!['email'] ?? '';
    final String phone = adminData!['phone'] ?? 'N/A';
    final String role = adminData!['role'] ?? 'Admin';
    final String bio = adminData!['bio'] ?? 'No bio added';
    final String? profileImage = adminData!['profileImageUrl'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 2,
        title: Text(
          loc.profile,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // 🧑‍💼 Profile Header
            GestureDetector(
              onTap: () {
                if (profileImage != null && profileImage.isNotEmpty) {
                  _showProfileDialog(profileImage);
                }
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        profileImage != null && profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 25),

            // 💼 Profile Info Cards
            _buildInfoTile(Icons.phone, loc.phone, phone),
            _buildInfoTile(Icons.badge, loc.role, role),
            _buildInfoTile(Icons.info_outline, loc.bio, bio),

            const SizedBox(height: 25),
            _buildSectionTitle("App Preferences"),

            const SizedBox(height: 30),

            // 🚪 Logout Button
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                loc.logout,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
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
          ],
        ),
      ),
    );
  }

  // 📋 Helper UI Components
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: _primaryColor),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}
