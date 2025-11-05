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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const tealColor = Colors.teal;

    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: tealColor)),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          loc.myProfile,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: tealColor,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: loc.editProfile,
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Profile Image ---
            CircleAvatar(
              radius: 65,
              backgroundColor: Colors.teal.shade100,
              backgroundImage:
                  userData!['profileImageUrl'] != null &&
                      userData!['profileImageUrl'].toString().isNotEmpty
                  ? NetworkImage(userData!['profileImageUrl'])
                  : const AssetImage('assets/default_profile.png')
                        as ImageProvider,
            ),
            const SizedBox(height: 16),

            // --- Name & Email ---
            Text(
              userData!['name'] ?? loc.unnamedUser,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              userData!['email'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 20),

            // --- Info Cards ---
            _buildInfoTile(
              icon: Icons.phone,
              label: loc.phone,
              value: userData!['phone'] ?? loc.notProvided,
            ),
            _buildInfoTile(
              icon: Icons.location_on,
              label: loc.address,
              value: userData!['address'] ?? loc.notProvided,
            ),
            _buildInfoTile(
              icon: Icons.info_outline,
              label: loc.bio,
              value: userData!['bio'] ?? loc.noBio,
            ),

            const SizedBox(height: 16),
            Divider(
              height: 32,
              color: Colors.grey.shade300,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),

            // --- Language Switcher ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.teal.shade100),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.language, color: tealColor),
                  const SizedBox(width: 10),
                  Text(
                    loc.language,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<Locale>(
                    value: currentLocale,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(10),
                    iconEnabledColor: tealColor,
                    onChanged: (locale) {
                      if (locale != null) _updateLanguage(locale);
                    },
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text("English"),
                      ),
                      DropdownMenuItem(
                        value: Locale('kn'),
                        child: Text("ಕನ್ನಡ"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Joined Date ---
            Text(
              "${loc.joinedOn}: $joinedDate",
              style: const TextStyle(color: Colors.grey),
            ),
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
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.teal.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
      ),
    );
  }
}
