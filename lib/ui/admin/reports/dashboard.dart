import 'package:flutter/material.dart';

// Import your pages
import 'collection.dart';
import 'sanitation.dart';
import 'processing/processing_dashboard.dart';
import 'expenditure/expenditures_dashboard.dart';
import 'compliance/compliance_dashboard.dart';
import 'overall_efficiency_card.dart';

class AdminReportsDashboard extends StatelessWidget {
  const AdminReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ReportTile(
        title: "Collection & Sanitation",
        icon: Icons.analytics_outlined,
        color: const Color(0xFF2C5F2D),
        isDialog: true,
      ),
      _ReportTile(
        title: "Processing Report",
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFFFFA726),
        page: const ProcessingDashboardPage(),
      ),
      _ReportTile(
        title: "Expenditures",
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF00796B),
        page: const ExpenditureDashboardPage(),
      ),
      _ReportTile(
        title: "Compliance",
        icon: Icons.rule_folder_outlined,
        color: const Color(0xFF5D4037),
        page: const ComplianceDashboardPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: Colors.grey.shade800,
            onPressed: () => Navigator.pop(context),
          ),
        ),

        title: Text(
          "Reports Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
      ),

      // ---------------- BODY ----------------
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // OVERALL EFFICIENCY CHART
          const OverallEfficiencyCard(),
          const SizedBox(height: 28),

          Text(
            "Report Categories",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 165,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (_, i) => _ReportCard(item: tiles[i]),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// DATA MODEL FOR TILES
// ----------------------------------------------------------------------
class _ReportTile {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? page;
  final bool isDialog;

  _ReportTile({
    required this.title,
    required this.icon,
    required this.color,
    this.page,
    this.isDialog = false,
  });
}

// ----------------------------------------------------------------------
// REPORT CARD UI
// ----------------------------------------------------------------------
class _ReportCard extends StatelessWidget {
  final _ReportTile item;

  const _ReportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _handleTap(context),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(2, 3),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: item.color.withOpacity(0.12),
              radius: 30,
              child: Icon(item.icon, color: item.color, size: 30),
            ),
            const SizedBox(height: 14),

            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // HANDLE TAP
  // ----------------------------------------------------------------------
  void _handleTap(BuildContext context) {
    if (item.isDialog) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.green),
                  title: const Text("Collection Report"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CollectionSummaryPage(),
                      ),
                    );
                  },
                ),
                Divider(color: Colors.grey.shade300, height: 0),

                ListTile(
                  leading: const Icon(
                    Icons.cleaning_services,
                    color: Colors.blue,
                  ),
                  title: const Text("Sanitation Report"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SanitationSummaryPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => item.page!));
    }
  }
}
