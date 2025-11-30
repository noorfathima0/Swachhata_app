import 'package:flutter/material.dart';

import 'weighment_entry.dart';
import 'equipment_hours_entry.dart';
import 'sales_entry.dart';
import 'processing_summary.dart';

class ProcessingDashboardPage extends StatelessWidget {
  const ProcessingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Processing Dashboard"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTile(
              icon: Icons.scale_outlined,
              color: Colors.blue,
              title: "Weighments",
              subtitle: "Record incoming waste quantities",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeighmentEntryPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTile(
              icon: Icons.cable,
              color: Colors.orange,
              title: "Equipment Running Hours",
              subtitle: "Log machine usage & hours",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EquipmentHoursEntryPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTile(
              icon: Icons.attach_money,
              color: Colors.green,
              title: "Sales",
              subtitle: "Record material sales & revenue",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesEntryPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTile(
              icon: Icons.bar_chart,
              color: const Color.fromARGB(255, 191, 213, 80),
              title: "Reports",
              subtitle: "View processing summaries & analytics",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProcessingSummaryPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
