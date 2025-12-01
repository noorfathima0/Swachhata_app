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
                  "User role updated to $role",
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
    }
  }

  Future<void> _updateUserStatus(String status) async {
    await _firestore.collection('users').doc(widget.userId).update({
      'status': status,
    });
    _fetchUserDetails();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: status == 'blocked'
                  ? Colors.red.shade600
                  : Color(0xFF27AE60),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'blocked'
                      ? Icons.block_rounded
                      : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  status == 'blocked'
                      ? "User has been blocked"
                      : "User has been unblocked",
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
    }
  }

  void _showProfileDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 100,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Color(0xFF27AE60);
      case 'blocked':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
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
              SizedBox(height: 16),
              Text(
                "Loading User Details...",
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

    if (userData == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            "User Details",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_off_rounded,
                    size: 70,
                    color: Colors.grey.shade300,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "User Not Found",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "The requested user profile could not be found",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "User Details",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Profile Header
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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userData!['profileImageUrl'] != null) {
                        _showProfileDialog(userData!['profileImageUrl']);
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 3,
                        ),
                        image: userData!['profileImageUrl'] != null
                            ? DecorationImage(
                                image: NetworkImage(
                                  userData!['profileImageUrl'],
                                ),
                                fit: BoxFit.cover,
                              )
                            : DecorationImage(
                                image: AssetImage('assets/default_profile.png'),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData!['name'] ?? 'Unnamed User',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userData!['email'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          (userData!['role'] ?? 'user')
                                                  .toLowerCase() ==
                                              'admin'
                                          ? Color(0xFF2C5F2D)
                                          : Color(0xFF3498DB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    (userData!['role'] ?? 'user').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  userData!['status'] ?? 'active',
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(
                                    userData!['status'] ?? 'active',
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        userData!['status'] ?? 'active',
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    (userData!['status'] ?? 'active')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(
                                        userData!['status'] ?? 'active',
                                      ),
                                      letterSpacing: 0.5,
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

            SizedBox(height: 20),

            // 📋 User Information
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "User Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoTile(
                    Icons.person_rounded,
                    "Name",
                    userData!['name'] ?? 'Not provided',
                  ),
                  _buildInfoTile(
                    Icons.phone_rounded,
                    "Phone",
                    userData!['phone'] ?? 'Not provided',
                  ),
                  _buildInfoTile(
                    Icons.language_rounded,
                    "Language",
                    userData!['language'] ?? 'English',
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // ⚙️ Management Actions
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Management Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              userData!['role'] == 'admin'
                                  ? Icons.person_remove_rounded
                                  : Icons.person_add_alt_1_rounded,
                              color: userData!['role'] == 'admin'
                                  ? Colors.blue.shade600
                                  : Color(0xFF2C5F2D),
                              size: 20,
                            ),
                            label: Text(
                              userData!['role'] == 'admin'
                                  ? "Demote to User"
                                  : "Promote to Admin",
                              style: TextStyle(
                                color: userData!['role'] == 'admin'
                                    ? Colors.blue.shade600
                                    : Color(0xFF2C5F2D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              final newRole = userData!['role'] == 'admin'
                                  ? 'user'
                                  : 'admin';
                              _updateUserRole(newRole);
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              userData!['status'] == 'blocked'
                                  ? Icons.lock_open_rounded
                                  : Icons.block_rounded,
                              color: userData!['status'] == 'blocked'
                                  ? Color(0xFF27AE60)
                                  : Colors.red.shade600,
                              size: 20,
                            ),
                            label: Text(
                              userData!['status'] == 'blocked'
                                  ? "Unblock User"
                                  : "Block User",
                              style: TextStyle(
                                color: userData!['status'] == 'blocked'
                                    ? Color(0xFF27AE60)
                                    : Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              final newStatus = userData!['status'] == 'blocked'
                                  ? 'active'
                                  : 'blocked';
                              _updateUserStatus(newStatus);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 📊 User Activity
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.analytics_rounded,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "User Activity",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildUserActivitySection(
                    "Complaints",
                    "complaints",
                    Icons.report_problem_rounded,
                  ),
                  SizedBox(height: 12),
                  _buildUserActivitySection(
                    "Activities",
                    "activities",
                    Icons.assignment_rounded,
                  ),
                  SizedBox(height: 12),
                  _buildUserActivitySection(
                    "Events Interested",
                    "events",
                    Icons.event_available_rounded,
                    field: 'interestedUsers',
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Color(0xFF2C5F2D), size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivitySection(
    String title,
    String collection,
    IconData icon, {
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
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2C5F2D),
              ),
            ),
          );
        }

        final hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        final count = hasData ? snapshot.data!.docs.length : 0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: hasData
                ? () {
                    // Show detailed list dialog
                    _showActivityDetails(title, snapshot.data!.docs, icon);
                  }
                : null,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasData ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasData
                      ? Color(0xFF2C5F2D).withOpacity(0.2)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasData
                          ? Color(0xFF2C5F2D).withOpacity(0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: hasData ? Color(0xFF2C5F2D) : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          hasData
                              ? "$count item${count > 1 ? 's' : ''} found"
                              : "No data available",
                          style: TextStyle(
                            color: hasData
                                ? Colors.grey.shade600
                                : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasData)
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF2C5F2D),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActivityDetails(
    String title,
    List<QueryDocumentSnapshot> docs,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2C5F2D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C5F2D).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.circle_rounded,
                        size: 8,
                        color: Color(0xFF2C5F2D),
                      ),
                    ),
                    title: Text(
                      data['type'] ?? data['title'] ?? 'Untitled',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Text(
                      data['description'] ??
                          data['details'] ??
                          'No description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
