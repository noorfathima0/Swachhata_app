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

  // 💙 Total collection efficiency (same math as daily report)
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

  // Count vehicles
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
      appBar: AppBar(
        title: const Text("Collection Summary"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
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
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  "Summary for $dateFormatted",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                _sectionTitle("Vehicle Count"),
                _countTile("Autos", _countByType("auto")),
                _countTile("Tippers", _countByType("tipper")),
                _countTile("Tractors", _countByType("tractor")),

                const SizedBox(height: 25),

                _sectionTitle("Collection Efficiency"),
                _efficiencyBar(efficiency),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
  );

  Widget _countTile(String type, int count) => ListTile(
    title: Text(type),
    trailing: Text(
      "$count",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
          color: color,
          backgroundColor: Colors.grey.shade300,
          minHeight: 12,
        ),
      ],
    );
  }
}
