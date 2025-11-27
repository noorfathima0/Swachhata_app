import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swachhata_app/ui/user/forum/forum_feed.dart';
import 'complaints/complaint_form.dart';
import 'complaints/complaint_list.dart';
import '../../providers/auth_provider.dart';
import 'activity/activity_form.dart';
import 'activity/my_activities.dart';
import 'events/events.dart';
import 'profile/profile.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final List<_DashboardItem> dashboardItems = [
      _DashboardItem(
        title: "Report an Issue",
        icon: Icons.report_problem_outlined,
        destination: const ComplaintForm(),
        color: Colors.red.shade600,
      ),
      _DashboardItem(
        title: "My Complaints",
        icon: Icons.assignment_outlined,
        destination: const ComplaintList(),
        color: Colors.orange.shade700,
      ),
      _DashboardItem(
        title: "Community Forum",
        icon: Icons.forum_outlined,
        destination: const UserForumPage(),
        color: Colors.blue.shade700,
      ),
      _DashboardItem(
        title: "Submit Activity",
        icon: Icons.add_task_outlined,
        destination: const ActivityFormPage(),
        color: Colors.green.shade700,
      ),
      _DashboardItem(
        title: "My Activities",
        icon: Icons.view_agenda_outlined,
        destination: const MyActivitiesPage(),
        color: Colors.teal.shade700,
      ),
      _DashboardItem(
        title: "Events",
        icon: Icons.calendar_month_outlined,
        destination: const UserEventsPage(),
        color: Colors.deepPurple.shade700,
      ),
      _DashboardItem(
        title: "Profile",
        icon: Icons.person_outline,
        destination: const UserProfilePage(),
        color: Colors.pink.shade700,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.teal.shade800,
        automaticallyImplyLeading: false,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sign Out",
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
              "Welcome Back 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Manage your activities, complaints, and events efficiently.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: dashboardItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 140,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return _DashboardCard(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Widget destination;
  final Color color;

  _DashboardItem({
    required this.title,
    required this.icon,
    required this.destination,
    required this.color,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => item.destination),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
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
