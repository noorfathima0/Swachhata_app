import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserDetailPage extends StatefulWidget {
  final String userId;
  const AdminUserDetailPage({super.key, required this.userId});

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool _loading = true;
  final Color _primaryColor = Colors.teal;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateUserRole(String role) async {
    await _firestore.collection('users').doc(widget.userId).update({
      'role': role,
    });
    _fetchUserDetails();
  }

  Future<void> _updateUserStatus(String status) async {
    await _firestore.collection('users').doc(widget.userId).update({
      'status': status,
    });
    _fetchUserDetails();
  }

  void _showProfileDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (userData == null) {
      return const Scaffold(body: Center(child: Text("❌ User not found.")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 2,
        title: Text(
          "${userData!['name']}'s Profile",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧑‍💼 Profile Header
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userData!['profileImageUrl'] != null) {
                        _showProfileDialog(userData!['profileImageUrl']);
                      }
                    },
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: userData!['profileImageUrl'] != null
                          ? NetworkImage(userData!['profileImageUrl'])
                          : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userData!['name'] ?? 'Unnamed User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData!['email'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🧾 Basic Info
            _buildSectionTitle("User Information"),
            _buildInfoTile("Name", userData!['name'] ?? 'Not provided'),
            _buildInfoTile("Phone", userData!['phone'] ?? 'Not provided'),
            _buildInfoTile("Language", userData!['language'] ?? 'English'),
            _buildInfoTile("Role", userData!['role'] ?? 'user'),
            _buildInfoTile("Status", userData!['status'] ?? 'active'),

            const SizedBox(height: 24),
            _buildSectionTitle("Management Tools"),

            // ⚙️ Management Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.admin_panel_settings, size: 20),
                    label: Text(
                      userData!['role'] == 'admin'
                          ? "Demote to User"
                          : "Promote to Admin",
                      style: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () {
                      final newRole = userData!['role'] == 'admin'
                          ? 'user'
                          : 'admin';
                      _updateUserRole(newRole);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: userData!['status'] == 'blocked'
                          ? Colors.green
                          : Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: Icon(
                      userData!['status'] == 'blocked'
                          ? Icons.lock_open
                          : Icons.block,
                      size: 20,
                    ),
                    label: Text(
                      userData!['status'] == 'blocked'
                          ? "Unblock User"
                          : "Block User",
                      style: const TextStyle(fontSize: 14),
                    ),
                    onPressed: () {
                      final newStatus = userData!['status'] == 'blocked'
                          ? 'active'
                          : 'blocked';
                      _updateUserStatus(newStatus);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle("User Activity"),

            _buildUserRelatedData("Complaints", "complaints"),
            _buildUserRelatedData("Activities", "activities"),
            _buildUserRelatedData(
              "Events Interested",
              "events",
              field: 'interestedUsers',
            ),
          ],
        ),
      ),
    );
  }

  // 🧩 Helper Widgets
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _buildInfoTile(String label, String value) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        leading: const Icon(Icons.info_outline_rounded, color: Colors.teal),
      ),
    );
  }

  Widget _buildUserRelatedData(
    String title,
    String collection, {
    String? field,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: field == null
          ? _firestore
                .collection(collection)
                .where('userId', isEqualTo: widget.userId)
                .get()
                .catchError(
                  (_) => _firestore
                      .collection(collection)
                      .where('uid', isEqualTo: widget.userId)
                      .get(),
                )
          : _firestore
                .collection(collection)
                .where(field, arrayContains: userData!['name'])
                .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(title),
              subtitle: const Text("No data found."),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.folder_copy_rounded, color: Colors.teal),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['type'] ?? data['title'] ?? 'Untitled'),
                subtitle: Text(
                  data['description'] ?? data['details'] ?? 'No description',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
