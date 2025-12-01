import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SanitationSummaryPage extends StatefulWidget {
  const SanitationSummaryPage({super.key});

  @override
  State<SanitationSummaryPage> createState() => _SanitationSummaryPageState();
}

class _SanitationSummaryPageState extends State<SanitationSummaryPage> {
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

  // 🟢 Sanitation Efficiency Calculation
  double _calculateSanitationEfficiency() {
    double total = 0;
    int count = 0;

    for (var doc in vehicles) {
      final data = doc.data() as Map<String, dynamic>;
      if (data["jobType"] != "sanitation") continue;

      final service = data["service"];
      if (service == null) continue;

      final startTs = service["startTime"];
      if (startTs is! Timestamp || !_isSameDate(startTs)) continue;

      if (data["type"] == "jcb") {
        final stops = List<String>.from(data["manualRoute"]?["stops"] ?? []);
        final completed = List<String>.from(service["completedStops"] ?? []);

        if (stops.isNotEmpty) {
          total += (completed.length / stops.length) * 100;
          count++;
        }
      } else {
        final km = (data["km"] ?? 0).toDouble();
        final traveled = (service["distanceKm"] ?? 0).toDouble();

        if (km > 0) {
          total += (traveled / km) * 100;
          count++;
        }
      }
    }

    return count == 0 ? 0 : total / count;
  }

  int _countType(String type) {
    return vehicles.where((v) {
      final d = v.data() as Map<String, dynamic>;
      return d["jobType"] == "sanitation" && d["type"] == type;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat("dd MMM yyyy").format(selectedDate);
    final efficiency = _calculateSanitationEfficiency();

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
          "Sanitation Summary",
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

                // ---------------- VEHICLE COUNT ----------------
                _sectionHeader("Vehicle Count"),

                _cardContainer(
                  children: [
                    _countRow("JCB", _countType("jcb")),
                    _countRow("Tractor", _countType("tractor")),
                  ],
                ),

                const SizedBox(height: 26),

                // ---------------- SANITATION EFFICIENCY ----------------
                _sectionHeader("Sanitation Efficiency"),

                _cardContainer(children: [_efficiencyBar(efficiency)]),
              ],
            ),
    );
  }

  // ---------------- SECTION HEADER ----------------
  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cleaning_services,
            color: Colors.teal.shade700,
            size: 18,
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
    );
  }

  // ---------------- CARD CONTAINER ----------------
  Widget _cardContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 10),
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

  // ---------------- COUNT ROW ----------------
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

  // ---------------- EFFICIENCY BAR ----------------
  Widget _efficiencyBar(double percent) {
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
