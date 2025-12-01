import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CollectionSummaryPage extends StatefulWidget {
  const CollectionSummaryPage({super.key});

  @override
  State<CollectionSummaryPage> createState() => _CollectionSummaryPageState();
}

class _CollectionSummaryPageState extends State<CollectionSummaryPage> {
  bool loading = true;
  DateTime selectedDate = DateTime.now();
  List<QueryDocumentSnapshot> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => loading = true);

    final snap = await FirebaseFirestore.instance.collection("vehicles").get();
    vehicles = snap.docs;

    setState(() => loading = false);
  }

  bool _isSameDate(Timestamp ts) {
    final d = ts.toDate();
    return d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day;
  }

  // 💙 Total collection efficiency (same math as Daily Report)
  double _calculateCollectionEfficiency() {
    double totalPercent = 0;
    int count = 0;

    for (var doc in vehicles) {
      final data = doc.data() as Map<String, dynamic>;
      if (data["jobType"] != "collection") continue;

      final service = data["service"];
      if (service == null) continue;

      final startTs = service["startTime"];
      if (startTs is! Timestamp) continue;
      if (!_isSameDate(startTs)) continue;

      final km = (data["km"] ?? 0).toDouble();
      final traveled = (service["distanceKm"] ?? 0).toDouble();

      if (km <= 0) continue;

      final percent = (traveled / km) * 100;
      totalPercent += percent;
      count++;
    }

    return count == 0 ? 0 : totalPercent / count;
  }

  int _countByType(String type) {
    return vehicles.where((v) {
      final d = v.data() as Map<String, dynamic>;
      return d["jobType"] == "collection" && d["type"] == type;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat("dd MMM yyyy").format(selectedDate);
    final efficiency = _calculateCollectionEfficiency();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

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
            onPressed: () => Navigator.pop(context),
            color: Colors.grey.shade800,
          ),
        ),

        title: Text(
          "Collection Summary",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.calendar_month, color: Colors.teal.shade700),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  "Summary for $dateFormatted",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),

                // ---------------- VEHICLE COUNTS ----------------
                _sectionHeader("Vehicle Count"),

                _infoCard(
                  children: [
                    _countRow("Autos", _countByType("auto")),
                    _countRow("Tippers", _countByType("tipper")),
                    _countRow("Tractors", _countByType("tractor")),
                  ],
                ),

                const SizedBox(height: 26),

                // ---------------- EFFICIENCY ----------------
                _sectionHeader("Collection Efficiency"),

                _infoCard(children: [_efficiencyMeter(efficiency)]),
              ],
            ),
    );
  }

  // ------------------- SECTION TITLE -------------------
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- REUSABLE CARD -------------------
  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ------------------- VEHICLE COUNT ROW -------------------
  Widget _countRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- EFFICIENCY BAR -------------------
  Widget _efficiencyMeter(double percent) {
    final color = percent >= 70
        ? Colors.green
        : percent >= 40
        ? Colors.orange
        : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${percent.toStringAsFixed(1)}%",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent / 100,
            color: color,
            backgroundColor: Colors.grey.shade300,
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}
