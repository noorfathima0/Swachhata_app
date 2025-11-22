import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/complaint_service.dart';
import 'complaint_detail.dart';
import 'package:intl/intl.dart';
import 'package:swachhata_app/l10n/app_localizations.dart';

class ComplaintList extends StatelessWidget {
  const ComplaintList({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = Provider.of<AuthProvider>(context).currentUser;
    final complaintService = ComplaintService();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.myComplaints),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? Center(
              child: Text(
                // "Please log in to view complaints." -> localized as "<Login> to view complaints."
                "${loc.login} ${loc.noData}", // fallback friendly message
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: complaintService.getUserComplaints(user.uid),
              builder: (context, snapshot) {
                // Loading spinner while fetching data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "${loc.error}: ${snapshot.error}",
                      style: TextStyle(fontSize: 16, color: Colors.red[700]),
                    ),
                  );
                }

                // No complaints
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          size: 64,
                          color: Colors.teal[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.noComplaints,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Extract and display complaint data
                final complaints = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final data =
                        complaints[index].data() as Map<String, dynamic>;

                    final timestamp = data['createdAt'] as Timestamp?;
                    final formattedDate = timestamp != null
                        ? DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(timestamp.toDate())
                        : loc.noData;

                    final rawStatus = (data['status'] ?? '').toString();
                    final localizedStatus = _localizedStatus(rawStatus, loc);
                    final statusColor = _getStatusColor(rawStatus);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.teal[50],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              data['imageUrl'] ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.teal[300],
                                    size: 30,
                                  ),
                            ),
                          ),
                        ),
                        title: Text(
                          data['type'] ?? loc.noData,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.teal[800],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "${loc.complaintStatus}: $localizedStatus",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.teal[400],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ComplaintDetail(data: complaints[index]),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                );
              },
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
    if (s.contains('resolved')) return Colors.green;
    if (s.contains('in progress') ||
        s.contains('progress') ||
        s.contains('submitted') ||
        s.contains('pending'))
      return Colors.orange;
    if (s.contains('rejected')) return Colors.red;
    return Colors.grey;
  }
}
