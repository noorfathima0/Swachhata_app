import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/complaint_service.dart';
import 'complaint_detail.dart';
import 'package:intl/intl.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';

class ComplaintList extends StatefulWidget {
  const ComplaintList({super.key});

  @override
  State<ComplaintList> createState() => _ComplaintListState();
}

class _ComplaintListState extends State<ComplaintList> {
  int _selectedFilter =
      0; // 0: All, 1: Pending, 2: In Progress, 3: Resolved, 4: Rejected
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
    'Rejected',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final loc = AppLocalizations.of(context)!;
    final user = Provider.of<AuthProvider>(context).currentUser;
    final complaintService = ComplaintService();

    // Red theme colors matching the Complaints dashboard box
    final Color primaryColor = const Color(0xFFEF5350);
    final Color primaryDark = const Color(0xFFE53935);
    final LinearGradient primaryGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEF5350), Color(0xFFE53935)],
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          loc.myComplaints,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? Center(
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
                  Text(
                    "${loc.login} ${loc.noData}",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
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
            )
          : Column(
              children: [
                // Filter Chips
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
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

                // Complaints List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: complaintService.getUserComplaints(user.uid),
                    builder: (context, snapshot) {
                      // Loading spinner while fetching data
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
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Error state
                      if (snapshot.hasError) {
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
                                  Icons.error_outline_rounded,
                                  color: primaryColor,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Text(
                                  "${loc.error}: ${snapshot.error}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Filter complaints based on selection
                      final allComplaints = snapshot.data?.docs ?? [];
                      final filteredComplaints = allComplaints.where((doc) {
                        if (_selectedFilter == 0) return true;

                        final data = doc.data() as Map<String, dynamic>;
                        final rawStatus = (data['status'] ?? '')
                            .toString()
                            .toLowerCase();

                        switch (_selectedFilter) {
                          case 1: // Pending
                            return rawStatus.contains('pending') ||
                                rawStatus.contains('submitted');
                          case 2: // In Progress
                            return rawStatus.contains('progress') ||
                                rawStatus.contains('in-progress');
                          case 3: // Resolved
                            return rawStatus.contains('resolved');
                          case 4: // Rejected
                            return rawStatus.contains('rejected');
                          default:
                            return true;
                        }
                      }).toList();

                      // No complaints
                      if (filteredComplaints.isEmpty) {
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
                                  Icons.report_problem_outlined,
                                  color: primaryColor,
                                  size: 50,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                allComplaints.isEmpty
                                    ? loc.noComplaints
                                    : "No ${_filterOptions[_selectedFilter].toLowerCase()} complaints",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (allComplaints.isNotEmpty &&
                                  _selectedFilter > 0)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _selectedFilter = 0),
                                  child: Text(
                                    "View all complaints",
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

                      // Extract and display complaint data
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: filteredComplaints.length,
                        itemBuilder: (context, index) {
                          final data =
                              filteredComplaints[index].data()
                                  as Map<String, dynamic>;

                          final timestamp = data['createdAt'] as Timestamp?;
                          final formattedDate = timestamp != null
                              ? DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(timestamp.toDate())
                              : loc.noData;

                          final rawStatus = (data['status'] ?? '').toString();
                          final localizedStatus = _localizedStatus(
                            rawStatus,
                            loc,
                          );
                          final statusColor = _getStatusColor(rawStatus);
                          final statusIcon = _getStatusIcon(rawStatus);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                      builder: (_) => ComplaintDetail(
                                        data: filteredComplaints[index],
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Complaint Image
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: primaryColor.withOpacity(
                                              0.2,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            data['imageUrl'] ?? '',
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  color: primaryColor
                                                      .withOpacity(0.1),
                                                  child: Icon(
                                                    Icons
                                                        .photo_camera_back_rounded,
                                                    color: primaryColor,
                                                    size: 30,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Complaint Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Type and Status
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    data['type'] ?? loc.noData,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
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
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Description snippet
                                            Text(
                                              data['description'] ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),

                                            // Date and Time
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

  // Map raw stored status to localized friendly text
  String _localizedStatus(String rawStatus, AppLocalizations loc) {
    final s = rawStatus.toLowerCase();
    if (s.contains('resolved')) return loc.complaintResolved;
    if (s.contains('rejected')) return loc.complaintRejected;
    if (s.contains('pending') || s.contains('submitted'))
      return loc.complaintPending;
    // if contains progress or "in-progress"
    if (s.contains('progress') || s.contains('in-progress'))
      return loc.complaintPending;
    // fallback to raw status if no matching localization key
    return rawStatus.isNotEmpty ? rawStatus : loc.noData;
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('resolved')) return Colors.green.shade600;
    if (s.contains('in progress') ||
        s.contains('progress') ||
        s.contains('submitted') ||
        s.contains('pending'))
      return Colors.orange.shade600;
    if (s.contains('rejected')) return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  IconData _getStatusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('resolved')) return Icons.check_circle_rounded;
    if (s.contains('in progress') || s.contains('progress'))
      return Icons.autorenew_rounded;
    if (s.contains('submitted') || s.contains('pending'))
      return Icons.access_time_rounded;
    if (s.contains('rejected')) return Icons.cancel_rounded;
    return Icons.help_rounded;
  }
}
