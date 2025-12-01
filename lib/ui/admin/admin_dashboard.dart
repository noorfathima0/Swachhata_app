import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

// Pages
import 'complaints/complaints_list.dart';
import 'activity/activities.dart';
import 'event/event.dart';
import 'forum/forum_page.dart';
import 'user_management/user_management.dart';
import 'profile/profile.dart';
import 'vehicle/vehicle_management.dart';
import 'driver/driver_management.dart';
import 'reports/dashboard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final List<_AdminDashboardItem> dashboardItems = [
      _AdminDashboardItem(
        title: "Operations",
        icon: Icons.dashboard_customize_outlined,
        color: const Color(0xFFE74C3C),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
        ),
        submenu: [
          _SubItem("View Complaints", const AdminComplaintPage()),
          _SubItem("Manage Activities", const AdminActivityPage()),
        ],
      ),

      _AdminDashboardItem(
        title: "Community Hub",
        icon: Icons.hub_outlined,
        color: const Color(0xFF3498DB),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
        ),
        submenu: [
          _SubItem("Forum Management", const AdminForumPage()),
          _SubItem("Events Oversight", const AdminEventPage()),
        ],
      ),

      _AdminDashboardItem(
        title: "User Management",
        icon: Icons.people_alt_outlined,
        color: const Color(0xFFE67E22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
        ),
        destination: const AdminUserManagementPage(),
      ),
      _AdminDashboardItem(
        title: "Vehicle Management",
        icon: Icons.directions_bus_outlined,
        color: const Color(0xFF9B59B6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
        ),
        destination: const AdminVehicleManagementPage(),
      ),
      _AdminDashboardItem(
        title: "Driver Management",
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF795548),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF795548), Color(0xFF5D4037)],
        ),
        destination: const AdminDriverManagementPage(),
      ),
      _AdminDashboardItem(
        title: "Reports Dashboard",
        icon: Icons.analytics_outlined,
        color: const Color(0xFF27AE60),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF27AE60), Color(0xFF229954)],
        ),
        destination: const AdminReportsDashboard(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Container(),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: PopupMenuButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2C5F2D),
                ),
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProfilePage()),
                  );
                } else if (value == 'logout') {
                  auth.logout();
                  Navigator.pop(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5F2D).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.red.shade600,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Logout",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
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

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, Administrator 👨‍💼",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Oversee and manage all system operations efficiently.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: dashboardItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 180,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return _AdminDashboardCard(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubItem {
  final String title;
  final Widget page;
  _SubItem(this.title, this.page);
}

class _AdminDashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final Widget? destination;
  final List<_SubItem>? submenu;

  _AdminDashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.gradient,
    this.destination,
    this.submenu,
  });
}

class _AdminDashboardCard extends StatelessWidget {
  final _AdminDashboardItem item;

  const _AdminDashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (item.submenu != null) {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: item.gradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(item.icon, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...item.submenu!.map(
                        (sub) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: item.color,
                              size: 14,
                            ),
                          ),
                          title: Text(
                            sub.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => sub.page),
                            );
                          },
                          shape: const Border(
                            bottom: BorderSide(color: Colors.grey, width: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => item.destination!),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: item.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                if (item.submenu != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${item.submenu!.length} options",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
