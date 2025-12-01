import 'package:flutter/material.dart';

import 'weighment_entry.dart';
import 'equipment_hours_entry.dart';
import 'sales_entry.dart';
import 'processing_summary.dart';

class ProcessingDashboardPage extends StatelessWidget {
  const ProcessingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ProcessTile(
        title: "Weighments",
        subtitle: "Record incoming waste quantities",
        icon: Icons.scale_outlined,
        color: Colors.teal.shade700,
        page: const WeighmentEntryPage(),
      ),
      _ProcessTile(
        title: "Equipment Running Hours",
        subtitle: "Log machine usage & operational hours",
        icon: Icons.precision_manufacturing_outlined,
        color: Colors.orange.shade700,
        page: const EquipmentHoursEntryPage(),
      ),
      _ProcessTile(
        title: "Sales",
        subtitle: "Record material sales & income",
        icon: Icons.attach_money,
        color: Colors.green.shade700,
        page: const SalesEntryPage(),
      ),
      _ProcessTile(
        title: "Reports",
        subtitle: "Processing summary & analytics",
        icon: Icons.bar_chart,
        color: Colors.blueGrey.shade700,
        page: const ProcessingSummaryPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Processing Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          itemCount: tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 140,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, i) => _DashboardCard(item: tiles[i]),
        ),
      ),
    );
  }
}

class _ProcessTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  _ProcessTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class _DashboardCard extends StatelessWidget {
  final _ProcessTile item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => item.page));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: item.color.withOpacity(.12),
              child: Icon(item.icon, size: 28, color: item.color),
            ),
            const SizedBox(width: 18),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
