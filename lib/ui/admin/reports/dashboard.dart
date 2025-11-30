import 'package:flutter/material.dart';

// Import your forms/pages here
import 'collection.dart';
import 'sanitation.dart';
import 'processing/processing_dashboard.dart';
import 'expenditure/expenditures_dashboard.dart';
import 'compliance/compliance_dashboard.dart';
import 'overall_efficiency_card.dart'; // ✅ IMPORT THE NEW CARD

class AdminReportsDashboard extends StatelessWidget {
  const AdminReportsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_ReportTile> tiles = [
      _ReportTile(
        title: "Collection & Sanitation",
        icon: Icons.analytics_outlined,
        color: Colors.green.shade700,
        isDialog: true,
      ),
      _ReportTile(
        title: "Processing Report",
        icon: Icons.pie_chart,
        color: Colors.orange.shade700,
        page: const ProcessingDashboardPage(),
      ),
      _ReportTile(
        title: "Expenditures",
        icon: Icons.construction_outlined,
        color: Colors.teal.shade700,
        page: const ExpenditureDashboardPage(),
      ),
      _ReportTile(
        title: "Compliance",
        icon: Icons.rule_folder_outlined,
        color: Colors.brown.shade700,
        page: const ComplianceDashboardPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Reports Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // -----------------------------------------------------------
          // 🔥 OVERALL EFFICIENCY CARD (Bar Chart + Average Efficiency)
          // -----------------------------------------------------------
          const OverallEfficiencyCard(),
          const SizedBox(height: 20),

          // -----------------------------------------------------------
          // 🔥 GRID DASHBOARD
          // -----------------------------------------------------------
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 160,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = tiles[index];
              return _ReportCard(item: item);
            },
          ),
        ],
      ),
    );
  }
}

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

/// CARD WIDGET
class _ReportCard extends StatelessWidget {
  final _ReportTile item;

  const _ReportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (item.isDialog) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                  const Divider(height: 0),
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
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.page!),
          );
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
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
