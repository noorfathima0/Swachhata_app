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
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          "Compliance Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fact_check_outlined,
                    size: 70,
                    color: Colors.teal.shade300,
                  ),
                  const SizedBox(height: 10),
                  const Text("No compliance records found"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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

  // ============================================================
  //               🔥 COMPLIANCE CARD (Upgraded UI)
  // ============================================================
  Widget _buildComplianceCard(BuildContext context, Map data) {
    final vehicle = data["vehicleNumber"] ?? "Unknown";

    final insuranceEnd = _toDate(data["insuranceEnd"]);
    final renewalDue = _toDate(data["renewalDue"]);
    final pollution = _toDate(data["pollutionRenew"]);
    final labor = _toDate(data["laborInsurance"]);
    final fc = _toDate(data["fcDue"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------------------
          // HEADER
          // ---------------------------------------------------------
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.withOpacity(.15),
                child: Icon(
                  Icons.local_shipping,
                  size: 22,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.teal.shade700),
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

          const SizedBox(height: 16),

          // ---------------------------------------------------------
          // ALERT TILES
          // ---------------------------------------------------------
          _alertTile("Insurance Renewal", insuranceEnd),
          _alertTile("General Renewal Due", renewalDue),
          _alertTile("Pollution License", pollution),
          _alertTile("Labor Insurance", labor),
          _alertTile("Vehicle FC", fc),

          const SizedBox(height: 18),

          // ---------------------------------------------------------
          // DOCUMENT BUTTONS
          // ---------------------------------------------------------
          _docButton("Pollution Document", data["pollutionFile"]),
          _docButton("Labor Insurance Document", data["laborFile"]),
          _docButton("FC Certificate", data["fcFile"]),
        ],
      ),
    );
  }

  // ============================================================
  //              🔥 ALERT TILE (Beautiful UI)
  // ============================================================
  Widget _alertTile(String title, DateTime? date) {
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_note, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title: ${date.toString().split(" ").first}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ),
          Text(
            message,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //              🔥 DOCUMENT BUTTON
  // ============================================================
  Widget _docButton(String label, String? url) {
    if (url == null || url.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextButton.icon(
        icon: Icon(Icons.attach_file, color: Colors.teal.shade700),
        label: Text(label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        onPressed: () => _openDocument(url),
      ),
    );
  }

  // ============================================================
  //      🔥 Popup Viewer (image or PDF fallback message)
  // ============================================================
  void _openDocument(String url) {
    final isPdf = url.toLowerCase().contains(".pdf");

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.teal.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Document Viewer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(child: isPdf ? _pdfMessage() : _imageViewer(url)),
          ],
        ),
      ),
    );
  }

  Widget _pdfMessage() {
    return const Center(
      child: Text(
        "PDF preview not supported.\nTap the link to open it in a browser.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: Colors.black54),
      ),
    );
  }

  Widget _imageViewer(String url) {
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

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
