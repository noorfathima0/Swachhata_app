import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_detail.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "User Management",
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF2C5F2D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.supervisor_account_rounded,
              color: Color(0xFF2C5F2D),
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading Users...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var users = snapshot.data!.docs;

                // 🔍 Apply search
                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      email.contains(_searchQuery.toLowerCase());
                }).toList();

                // 🧩 Apply role filter
                if (_roleFilter != 'All') {
                  users = users
                      .where(
                        (doc) =>
                            ((doc.data() as Map)['role'] ?? 'user')
                                .toString()
                                .toLowerCase() ==
                            _roleFilter.toLowerCase(),
                      )
                      .toList();
                }

                // ⚙️ Apply status filter
                if (_statusFilter != 'All') {
                  users = users
                      .where(
                        (doc) =>
                            ((doc.data() as Map)['status'] ?? 'active')
                                .toString()
                                .toLowerCase() ==
                            _statusFilter.toLowerCase(),
                      )
                      .toList();
                }

                if (users.isEmpty) {
                  return _buildEmptyState();
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      final role = (data['role'] ?? 'user').toString();
                      final status = (data['status'] ?? 'active').toString();
                      final isBlocked = status.toLowerCase() == 'blocked';
                      final email = data['email'] ?? 'No email';
                      final name = data['name'] ?? 'Unnamed User';
                      final profileImage = data['profileImageUrl'];

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(bottom: 16),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminUserDetailPage(userId: userId),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  // 👤 Profile Image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 2,
                                      ),
                                      image: profileImage != null
                                          ? DecorationImage(
                                              image: NetworkImage(profileImage),
                                              fit: BoxFit.cover,
                                            )
                                          : DecorationImage(
                                              image: AssetImage(
                                                'assets/default_profile.png',
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: 16),

                                  // 📝 User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17,
                                                  color: Colors.grey.shade800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    _getRoleColor(role),
                                                    _getRoleColor(
                                                      role,
                                                    ).withOpacity(0.8),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                role.toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: isBlocked
                                                    ? Colors.red.shade50
                                                    : Colors.green.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isBlocked
                                                    ? Icons.block_rounded
                                                    : Icons
                                                          .check_circle_rounded,
                                                color: isBlocked
                                                    ? Colors.red.shade600
                                                    : Colors.green.shade600,
                                                size: 14,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.grey.shade600,
                                                size: 14,
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
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Color(0xFF2C5F2D);
      case 'user':
        return Color(0xFF3498DB);
      default:
        return Colors.grey.shade600;
    }
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

  // 🎛️ Filters Section
  Widget _buildFilters() {
    return Container(
      margin: EdgeInsets.all(20),
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
                  Icons.filter_list_rounded,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Filter Users",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // 🔍 Search Bar
          TextField(
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.search_rounded, color: Color(0xFF2C5F2D)),
              ),
              hintText: "Search by name or email",
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          SizedBox(height: 16),

          // 🧩 Role & Status Filters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Role",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _roleFilter,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF2C5F2D),
                          ),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: ['All', 'Admin', 'User']
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _roleFilter = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF2C5F2D),
                          ),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: ['All', 'Active', 'Blocked']
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(r),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          r,
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _statusFilter = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
                Icons.people_outline_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No Users Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? "No users match your search query"
                  : _roleFilter != 'All' || _statusFilter != 'All'
                  ? "No users match the selected filters"
                  : "No users registered yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 48,
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
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  "Clear Filters",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
                  setState(() {
                    _searchQuery = '';
                    _roleFilter = 'All';
                    _statusFilter = 'All';
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
