import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';
import 'activity_detail.dart';

class MyActivitiesPage extends StatefulWidget {
  const MyActivitiesPage({super.key});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> {
  int _selectedFilter =
      0; // 0: All, 1: Pending, 2: In Progress, 3: Approved, 4: Rejected
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'In Progress',
    'Approved',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);

    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    // ✅ Green theme colors matching the Activities dashboard box
    final Color primaryColor = const Color(0xFF4CAF50);
    final Color primaryDark = const Color(0xFF388E3C);
    final LinearGradient primaryGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    );

    if (user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: primaryColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  loc.loginToViewActivities,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    loc.login,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.myActivities,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filterOptions.length, (index) {
                  final isSelected = _selectedFilter == index;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _filterOptions[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? index : 0;
                        });
                      },
                      backgroundColor: isDarkMode
                          ? const Color(0xFF2D2D2D)
                          : Colors.grey.shade100,
                      selectedColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Activities List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.loading,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.cleaning_services_rounded,
                            color: primaryColor,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          loc.noActivitiesFound,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start by submitting your first activity",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter activities based on selection
                final allActivities = snapshot.data!.docs;
                final filteredActivities = allActivities.where((doc) {
                  if (_selectedFilter == 0) return true;

                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? 'Pending')
                      .toString()
                      .toLowerCase();

                  switch (_selectedFilter) {
                    case 1: // Pending
                      return status.contains('pending');
                    case 2: // In Progress
                      return status.contains('progress') ||
                          status.contains('in-progress');
                    case 3: // Approved
                      return status.contains('approved');
                    case 4: // Rejected
                      return status.contains('rejected');
                    default:
                      return true;
                  }
                }).toList();

                if (filteredActivities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No ${_filterOptions[_selectedFilter].toLowerCase()} activities",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (allActivities.isNotEmpty && _selectedFilter > 0)
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectedFilter = 0),
                            child: Text(
                              "View all activities",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity =
                        filteredActivities[index].data()
                            as Map<String, dynamic>;
                    final id = filteredActivities[index].id;
                    final title = activity['title'] ?? loc.untitledActivity;
                    final description = activity['description'] ?? '';
                    final status = (activity['status'] ?? 'Pending').toString();
                    final createdAt =
                        (activity['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    final formattedDate = DateFormat(
                      'dd MMM, hh:mm a',
                    ).format(createdAt);

                    final List<String> mediaUrls =
                        (activity['mediaUrls'] as List?)?.cast<String>() ?? [];

                    final statusColor = _statusColor(status);
                    final statusIcon = _statusIcon(status);
                    final localizedStatus = _localizedStatus(status, loc);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDarkMode
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailPage(
                                  activityId: id,
                                  activityData: activity,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: mediaUrls.isNotEmpty
                                        ? Image.network(
                                            mediaUrls.first,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: primaryColor.withOpacity(
                                                0.1,
                                              ),
                                              child: Icon(
                                                Icons
                                                    .image_not_supported_rounded,
                                                color: primaryColor,
                                                size: 30,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: primaryColor.withOpacity(
                                              0.1,
                                            ),
                                            child: Icon(
                                              Icons.photo_camera_back_rounded,
                                              color: primaryColor,
                                              size: 30,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  statusIcon,
                                                  color: statusColor,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  localizedStatus,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      if (description.isNotEmpty)
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.grey[700],
                                          ),
                                        ),

                                      const SizedBox(height: 8),

                                      // Date and Image Count
                                      Row(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 14,
                                                color: isDarkMode
                                                    ? Colors.white60
                                                    : Colors.black45,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? Colors.white60
                                                      : Colors.black45,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.photo_library_rounded,
                                                size: 14,
                                                color: isDarkMode
                                                    ? Colors.white60
                                                    : Colors.black45,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${mediaUrls.length} photo${mediaUrls.length != 1 ? 's' : ''}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? Colors.white60
                                                      : Colors.black45,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Chevron Icon
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Helper: status color
  Color _statusColor(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      case 'in progress':
      case 'in-progress':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600; // For pending
    }
  }

  // 🔹 Helper: status icon
  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'in progress':
      case 'in-progress':
        return Icons.autorenew_rounded;
      default:
        return Icons.access_time_rounded; // For pending
    }
  }

  // 🔹 Helper: localized status text
  String _localizedStatus(String status, AppLocalizations loc) {
    final s = status.toLowerCase();
    if (s == 'approved') return loc.statusApproved;
    if (s == 'rejected') return loc.statusRejected;
    if (s == 'resolved') return loc.statusResolved;
    if (s == 'in-progress' || s == 'in progress') return loc.statusInProgress;
    if (s == 'pending') return loc.statusPending;
    return status;
  }
}
