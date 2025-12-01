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

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final List<_DashboardItem> dashboardItems = [
    _DashboardItem(
      title: "Complaints",
      icon: Icons.gavel_rounded,
      color: const Color(0xFFEF5350),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEF5350), Color(0xFFE53935)],
      ),
      isCombined: true,
      subItems: [
        _SubItem(
          title: "Report Issue",
          icon: Icons.report_problem_rounded,
          destination: const ComplaintForm(),
        ),
        _SubItem(
          title: "My Complaints",
          icon: Icons.assignment_turned_in_rounded,
          destination: const ComplaintList(),
        ),
      ],
    ),
    _DashboardItem(
      title: "Activities",
      icon: Icons.cleaning_services_rounded,
      color: const Color(0xFF4CAF50),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
      ),
      isCombined: true,
      subItems: [
        _SubItem(
          title: "New Activity",
          icon: Icons.add_task_rounded,
          destination: const ActivityFormPage(),
        ),
        _SubItem(
          title: "My Activities",
          icon: Icons.checklist_rounded,
          destination: const MyActivitiesPage(),
        ),
      ],
    ),
    _DashboardItem(
      title: "Community",
      icon: Icons.forum_rounded,
      destination: const UserForumPage(),
      color: const Color(0xFF2196F3),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      ),
      isCombined: false,
    ),
    _DashboardItem(
      title: "Events",
      icon: Icons.event_available_rounded,
      destination: const UserEventsPage(),
      color: const Color(0xFF673AB7),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
      ),
      isCombined: false,
    ),
    _DashboardItem(
      title: "Profile",
      icon: Icons.person_rounded,
      destination: const UserProfilePage(),
      color: const Color(0xFFE91E63),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
      ),
      isCombined: false,
    ),
    _DashboardItem(
      title: "Logout",
      icon: Icons.logout_rounded,
      color: const Color(0xFF607D8B),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF607D8B), Color(0xFF455A64)],
      ),
      isCombined: false,
      isLogout: true,
    ),
  ];

  void _onItemTapped(_DashboardItem item) {
    if (item.isLogout) {
      _showLogoutDialog();
    } else if (item.isCombined) {
      _showOptionsDialog(item);
    } else {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              item.destination!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _showOptionsDialog(_DashboardItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDialogSubtitle(item.title),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Options List
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: item.subItems!.map((subItem) {
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  subItem.destination,
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(subItem.icon, color: item.color, size: 22),
                    ),
                    title: Text(
                      subItem.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      _getOptionDescription(subItem.title),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 24),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Cancel Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: item.color,
                    side: BorderSide(color: item.color, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDialogSubtitle(String title) {
    switch (title) {
      case "Complaints":
        return "Manage your issue reports and complaints";
      case "Activities":
        return "Submit and track your cleanup activities";
      default:
        return "";
    }
  }

  String _getOptionDescription(String title) {
    switch (title) {
      case "Report Issue":
        return "File a new complaint about community issues";
      case "My Complaints":
        return "View and track your submitted complaints";
      case "New Activity":
        return "Submit a new cleanup or maintenance activity";
      case "My Activities":
        return "View your activity history and records";
      default:
        return "";
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              auth.logout();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00796B), Color(0xFF004D40)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00796B).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back 👋",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Make a difference in your community today!",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard Grid
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: dashboardItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return _DashboardCard(
                    item: item,
                    onTap: () => _onItemTapped(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Widget? destination;
  final Color color;
  final LinearGradient gradient;
  final bool isCombined;
  final bool isLogout;
  final List<_SubItem>? subItems;

  _DashboardItem({
    required this.title,
    required this.icon,
    this.destination,
    required this.color,
    required this.gradient,
    required this.isCombined,
    this.isLogout = false,
    this.subItems,
  });
}

class _SubItem {
  final String title;
  final IconData icon;
  final Widget destination;

  _SubItem({
    required this.title,
    required this.icon,
    required this.destination,
  });
}

class _DashboardCard extends StatefulWidget {
  final _DashboardItem item;
  final VoidCallback onTap;

  const _DashboardCard({required this.item, required this.onTap});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..scale(_isHovering ? 1.03 : 1.0),
          decoration: BoxDecoration(
            gradient: widget.item.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(widget.item.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                widget.item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),

              // Subtitle based on item type
              const SizedBox(height: 8),
              Text(
                _getSubtitle(widget.item.title, widget.item.isCombined),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(String title, bool isCombined) {
    if (isCombined) {
      return "Tap to see options";
    }

    switch (title) {
      case "Community":
        return "Discuss & share";
      case "Events":
        return "Join activities";
      case "Profile":
        return "Account settings";
      case "Logout":
        return "Sign out of account";
      default:
        return "";
    }
  }
}
