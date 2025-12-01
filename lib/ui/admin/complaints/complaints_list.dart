import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/complaint_service.dart';
import 'complaint_detail.dart';

class AdminComplaintPage extends StatefulWidget {
  const AdminComplaintPage({super.key});

  @override
  State<AdminComplaintPage> createState() => _AdminComplaintPageState();
}

class _AdminComplaintPageState extends State<AdminComplaintPage> {
  final ComplaintService _service = ComplaintService();

  final Map<String, Color> _statusColors = {
    "Submitted": Color(0xFF3498DB),
    "In-Progress": Color(0xFFE67E22),
    "Resolved": Color(0xFF27AE60),
    "Rejected": Colors.red.shade600,
  };

  Color _getStatusColor(String status) => _statusColors[status] ?? Colors.grey;

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'garbage':
        return Icons.delete_outline;
      case 'water leakage':
        return Icons.water_drop_outlined;
      case 'road damage':
        return Icons.construction_outlined;
      case 'street light':
        return Icons.lightbulb_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Complaint Management",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          _buildStats(),
          SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getAllComplaints(),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading Complaints...",
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

                final complaints = snapshot.data!.docs;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final doc = complaints[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['createdAt'] as Timestamp?)?.toDate();
                      final formattedDate = date != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                          : 'N/A';
                      final status = data['status'] ?? 'Unknown';
                      final type = data['type'] ?? 'Unknown';

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
                                      ComplaintDetailPage(data: doc),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getTypeIcon(type),
                                      color: _getStatusColor(status),
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
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
                                                type,
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
                                                    _getStatusColor(status),
                                                    _getStatusColor(
                                                      status,
                                                    ).withOpacity(0.8),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                        Text(
                                          data['description'] ??
                                              'No description',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox(height: 100);

          final complaints = snapshot.data!.docs;
          final total = complaints.length;
          final resolved = complaints
              .where((doc) => (doc['status'] ?? '') == 'Resolved')
              .length;
          final inProgress = complaints
              .where((doc) => (doc['status'] ?? '') == 'In-Progress')
              .length;
          final submitted = complaints
              .where((doc) => (doc['status'] ?? '') == 'Submitted')
              .length;

          return Row(
            children: [
              _buildStatCard("Total", total, Color(0xFF3498DB)),
              SizedBox(width: 12),
              _buildStatCard("Resolved", resolved, Color(0xFF27AE60)),
              SizedBox(width: 12),
              _buildStatCard("In Progress", inProgress, Color(0xFFE67E22)),
              SizedBox(width: 12),
              _buildStatCard("Submitted", submitted, Color(0xFF9B59B6)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatIcon(title), color: color, size: 18),
            ),
            SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatIcon(String title) {
    switch (title) {
      case 'Total':
        return Icons.list_alt_rounded;
      case 'Resolved':
        return Icons.check_circle_rounded;
      case 'In Progress':
        return Icons.update_rounded;
      case 'Submitted':
        return Icons.pending_actions_rounded;
      default:
        return Icons.analytics_rounded;
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
                Icons.inbox_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No Complaints Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "All new complaints will appear here automatically for review and action.",
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
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
