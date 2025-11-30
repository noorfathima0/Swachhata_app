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
        icon: Icons.dashboard_customize,
        color: Colors.red.shade700,
        submenu: [
          _SubItem("View Complaints", const AdminComplaintPage()),
          _SubItem("Manage Activities", const AdminActivityPage()),
        ],
      ),

      _AdminDashboardItem(
        title: "Community Hub",
        icon: Icons.hub_outlined,
        color: Colors.blue.shade700,
        submenu: [
          _SubItem("Forum Management", const AdminForumPage()),
          _SubItem("Events Oversight", const AdminEventPage()),
        ],
      ),

      _AdminDashboardItem(
        title: "User Management",
        icon: Icons.people_alt_outlined,
        color: Colors.orange.shade700,
        destination: const AdminUserManagementPage(),
      ),
      _AdminDashboardItem(
        title: "Vehicle Management",
        icon: Icons.directions_bus,
        color: Colors.indigo.shade700,
        destination: const AdminVehicleManagementPage(),
      ),
      _AdminDashboardItem(
        title: "Driver Management",
        icon: Icons.local_shipping_outlined,
        color: Colors.brown.shade700,
        destination: const AdminDriverManagementPage(),
      ),
      _AdminDashboardItem(
        title: "Reports Dashboard",
        icon: Icons.analytics_outlined,
        color: Colors.green.shade700,
        destination: const AdminReportsDashboard(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.teal.shade800,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Container(),

        // -----------------------
        // 🔽 PROFILE DROPDOWN MENU
        // -----------------------
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.person, size: 28),
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                  children: const [
                    Icon(Icons.person, color: Colors.teal),
                    SizedBox(width: 10),
                    Text("Profile"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Administrator 👨‍💼",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Oversee and manage all system operations efficiently.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: dashboardItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
  final Widget? destination;
  final List<_SubItem>? submenu;

  _AdminDashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    this.destination,
    this.submenu,
  });
}

class _AdminDashboardCard extends StatelessWidget {
  final _AdminDashboardItem item;

  const _AdminDashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (item.submenu != null) {
          // -----------------------
          // SHOW SUB-MENU DIALOG
          // -----------------------
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...item.submenu!.map(
                    (sub) => ListTile(
                      title: Text(sub.title),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => sub.page),
                        );
                      },
                    ),
                  ),
                ],
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
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: item.color.withOpacity(0.15),
                radius: 28,
                child: Icon(item.icon, color: item.color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
