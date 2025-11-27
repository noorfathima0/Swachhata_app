import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swachhata_app/ui/admin/forum/forum_page.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'complaints/complaints_list.dart';
import 'activity/activities.dart';
import 'event/event.dart';
import 'user_management/user_management.dart';
import 'profile/profile.dart';
import 'vehicle/vehicle_management.dart';
import 'driver/driver_management.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final List<_AdminDashboardItem> dashboardItems = [
      _AdminDashboardItem(
        title: "View Complaints",
        icon: Icons.list_alt_outlined,
        color: Colors.red.shade700,
        destination: const AdminComplaintPage(),
      ),
      _AdminDashboardItem(
        title: "Forum Management",
        icon: Icons.forum_outlined,
        color: Colors.blue.shade700,
        destination: const AdminForumPage(),
      ),
      _AdminDashboardItem(
        title: "Manage Activities",
        icon: Icons.task_outlined,
        color: Colors.green.shade700,
        destination: const AdminActivityPage(),
      ),
      _AdminDashboardItem(
        title: "Events Oversight",
        icon: Icons.event_note_outlined,
        color: Colors.deepPurple.shade700,
        destination: const AdminEventPage(),
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
        title: "Admin Profile",
        icon: Icons.person_outline,
        color: Colors.teal.shade700,
        destination: const AdminProfilePage(),
      ),
      _AdminDashboardItem(
        title: "Driver Management",
        icon: Icons.local_shipping_outlined,
        color: Colors.brown.shade700,
        destination: const AdminDriverManagementPage(),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
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

class _AdminDashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;

  _AdminDashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.destination,
  });
}

class _AdminDashboardCard extends StatelessWidget {
  final _AdminDashboardItem item;

  const _AdminDashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.destination),
      ),
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
