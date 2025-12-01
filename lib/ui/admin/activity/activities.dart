import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'activity_detail.dart';

class AdminActivityPage extends StatelessWidget {
  const AdminActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "User Activities Review",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading Activities...",
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

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final activities = snapshot.data!.docs;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final doc = activities[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'Untitled Activity';
                final userName = data['userName'] ?? 'Unknown User';
                final status = data['status'] ?? 'Pending';
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                final formattedDate = createdAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
                    : 'Unknown Date';
                final mediaUrls =
                    (data['mediaUrls'] as List?)?.cast<String>() ?? [];
                final hasMedia = mediaUrls.isNotEmpty;

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
                            builder: (_) => AdminActivityDetailPage(
                              activityId: doc.id,
                              activityData: data,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon section
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getActivityIcon(data),
                                color: _statusColor(status),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),

                            // Content section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
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
                                              _statusColor(status),
                                              _statusColor(
                                                status,
                                              ).withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: Colors.blue.shade600,
                                          size: 14,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      if (hasMedia)
                                        Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.photo_library_rounded,
                                            color: Colors.purple.shade600,
                                            size: 14,
                                          ),
                                        ),
                                      if (hasMedia) SizedBox(width: 6),
                                      if (hasMedia)
                                        Text(
                                          "${mediaUrls.length} photo${mediaUrls.length > 1 ? 's' : ''}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
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
    );
  }

  IconData _getActivityIcon(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toLowerCase();
    final description = (data['description'] ?? '').toLowerCase();

    if (title.contains('clean') || description.contains('clean')) {
      return Icons.cleaning_services_rounded;
    } else if (title.contains('plant') || description.contains('plant')) {
      return Icons.eco_rounded;
    } else if (title.contains('recycl') || description.contains('recycl')) {
      return Icons.recycling_rounded;
    } else if (title.contains('awareness') ||
        description.contains('awareness')) {
      return Icons.campaign_rounded;
    } else if (title.contains('meet') || description.contains('meet')) {
      return Icons.groups_rounded;
    } else {
      return Icons.volunteer_activism_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Color(0xFF27AE60);
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Color(0xFFE67E22);
    }
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
                Icons.assignment_turned_in_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No Activities Pending",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "All user-submitted activities will appear here for review and approval.",
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
                  "Refresh",
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
                  // This will trigger the stream to rebuild
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
