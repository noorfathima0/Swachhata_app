import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'compliance_entry.dart';

class ComplianceDashboardPage extends StatefulWidget {
  const ComplianceDashboardPage({super.key});

  @override
  State<ComplianceDashboardPage> createState() =>
      _ComplianceDashboardPageState();
}

class _ComplianceDashboardPageState extends State<ComplianceDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Compliance Dashboard"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplianceEntryPage()),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("compliance")
            .orderBy("vehicleNumber")
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No compliance records found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              data["id"] = docs[i].id;

              return _buildComplianceCard(context, data);
            },
          );
        },
      ),
    );
  }

  // -----------------------------------------------------
  // 🔥 CARD UI WITH 30-DAY WARNING + VIEW DOCUMENTS + EDIT
  // -----------------------------------------------------
  Widget _buildComplianceCard(BuildContext context, Map data) {
    final vehicle = data["vehicleNumber"] ?? "Unknown";

    // Dates
    final DateTime? insuranceEnd = _toDate(data["insuranceEnd"]);
    final DateTime? renewalDue = _toDate(data["renewalDue"]);
    final DateTime? pollution = _toDate(data["pollutionRenew"]);
    final DateTime? labor = _toDate(data["laborInsurance"]);
    final DateTime? fc = _toDate(data["fcDue"]);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER — vehicle + edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplianceEntryPage(
                          docId: data["id"],
                          existingData: data as Map<String, dynamic>,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const Divider(),

            // Notification badges
            _buildAlertTile("Insurance Renewal", insuranceEnd),
            _buildAlertTile("General Renewal Due", renewalDue),
            _buildAlertTile("Pollution Licence", pollution),
            _buildAlertTile("Labor Insurance", labor),
            _buildAlertTile("Vehicle FC", fc),

            const SizedBox(height: 10),

            // Documents view buttons
            _docButton("Pollution Document", data["pollutionFile"]),
            _docButton("Labor Insurance Document", data["laborFile"]),
            _docButton("FC Certificate", data["fcFile"]),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // 🔥 EXPIRY + 30-DAY WARNING LOGIC
  // -----------------------------------------------------
  Widget _buildAlertTile(String title, DateTime? date) {
    if (date == null) return const SizedBox();

    final now = DateTime.now();
    final daysLeft = date.difference(now).inDays;

    Color color;
    String message;

    if (daysLeft < 0) {
      color = Colors.red;
      message = "Expired!";
    } else if (daysLeft <= 30) {
      color = Colors.orange;
      message = "Due in $daysLeft days";
    } else {
      color = Colors.green;
      message = "Valid ($daysLeft days left)";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$title: ${date.toString().split(" ").first}",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // VIEW DOCUMENT BUTTON
  // -----------------------------------------------------
  Widget _docButton(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox();

    return TextButton.icon(
      icon: const Icon(Icons.attach_file, color: Colors.teal),
      label: Text(label),
      onPressed: () {
        _openDocumentViewer(url);
      },
    );
  }

  // -----------------------------------------------------
  // WEBSITE-STYLE POPUP TO SHOW URL
  // -----------------------------------------------------
  void _openDocumentViewer(String url) {
    final isPdf = url.toLowerCase().contains(".pdf");

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.teal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Document Viewer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: isPdf ? _buildPdfViewer(url) : _buildImageViewer(url),
              ),
            ],
          ),
        );
      },
    );
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  Widget _buildPdfViewer(String url) {
    return const Center(
      child: Text(
        "PDF Preview Not Supported.\nTap button to open in browser.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildImageViewer(String url) {
    return InteractiveViewer(
      maxScale: 5,
      minScale: 0.5,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Center(child: Text("Failed to load image")),
      ),
    );
  }
}
