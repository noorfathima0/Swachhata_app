import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProcessingSummaryPage extends StatefulWidget {
  const ProcessingSummaryPage({super.key});

  @override
  State<ProcessingSummaryPage> createState() => _ProcessingSummaryPageState();
}

class _ProcessingSummaryPageState extends State<ProcessingSummaryPage> {
  DateTime selectedDate = DateTime.now();

  double organic = 0, dry = 0, mixed = 0, sanitary = 0;
  double compost = 0, recyclable = 0, rdf = 0, inert = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        loading = true;
        organic = dry = mixed = sanitary = 0;
        compost = recyclable = rdf = inert = 0;
      });

      loadData();
    }
  }

  bool isSameDate(Timestamp ts) {
    final d = ts.toDate();
    return d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day;
  }

  Future<void> loadData() async {
    try {
      // ---------------------------
      // READ WEIGHMENTS
      // ---------------------------
      final weighSnap = await FirebaseFirestore.instance
          .collection("processing_weighments")
          .get();

      for (var doc in weighSnap.docs) {
        final data = doc.data();

        if (data["createdAt"] is Timestamp && !isSameDate(data["createdAt"])) {
          continue;
        }

        organic += (data["organicTons"] ?? 0).toDouble();
        dry += (data["dryTons"] ?? 0).toDouble();
        mixed += (data["mixedTons"] ?? 0).toDouble();
        sanitary += (data["sanitaryTons"] ?? 0).toDouble();
      }

      // ---------------------------
      // READ SALES
      // ---------------------------
      final salesSnap = await FirebaseFirestore.instance
          .collection("processing_sales")
          .get();

      for (var doc in salesSnap.docs) {
        final data = doc.data();

        if (data["createdAt"] is Timestamp && !isSameDate(data["createdAt"])) {
          continue;
        }

        compost += (data["compostTons"] ?? 0).toDouble();
        recyclable += (data["recyclableTons"] ?? 0).toDouble();
        rdf += (data["rdfTons"] ?? 0).toDouble();
        inert += (data["inertTons"] ?? 0).toDouble();
      }
    } catch (e) {
      print("❌ Firestore READ failed: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalInput = organic + dry + mixed + sanitary;

    final segregationEff = totalInput == 0 ? 0 : (mixed / totalInput) * 100;
    final totalOutput = compost + recyclable + rdf + inert;
    final processingEff = totalInput == 0
        ? 0
        : (totalOutput / totalInput) * 100;

    final formattedDate = DateFormat("dd MMM yyyy").format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Processing Summary"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDate,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Summary for $formattedDate",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _buildPieChart(totalInput),

                const SizedBox(height: 20),

                // _buildPercentTile("Organic Waste", organic, totalInput),
                // _buildPercentTile("Dry Waste", dry, totalInput),
                // _buildPercentTile("Mixed Waste", mixed, totalInput),
                // _buildPercentTile("Sanitary Waste", sanitary, totalInput),
                const SizedBox(height: 30),

                _buildCard(
                  title: "Segregation Efficiency",
                  value: "${segregationEff.toStringAsFixed(2)}%",
                  color: Colors.deepPurple,
                ),

                const SizedBox(height: 20),

                _buildCard(
                  title: "Processing Efficiency",
                  value: "${processingEff.toStringAsFixed(2)}%",
                  color: Colors.green.shade700,
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------
  // PIE CHART WITH LABELS
  // ---------------------------------------------------
  Widget _buildPieChart(double total) {
    if (total == 0) return const Text("No data", textAlign: TextAlign.center);

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          sections: [
            _pieSlice("Organic", organic, total, Colors.green),
            _pieSlice("Dry", dry, total, Colors.blue),
            _pieSlice("Mixed", mixed, total, Colors.orange),
            _pieSlice("Sanitary", sanitary, total, Colors.red),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _pieSlice(
    String name,
    double value,
    double total,
    Color color,
  ) {
    final percent = total == 0 ? 0 : (value / total) * 100;
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 60,
      title: "$name\n${percent.toStringAsFixed(1)}%",
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  // ---------------------------------------------------
  // PERCENT BAR TILE
  // ---------------------------------------------------
  // Widget _buildPercentTile(String name, double value, double total) {
  //   final percent = total == 0 ? 0 : (value / total) * 100;

  //   return Card(
  //     child: ListTile(
  //       title: Text(name),
  //       subtitle: LinearProgressIndicator(
  //         value: percent / 100,
  //         color: Colors.teal,
  //       ),
  //       trailing: Text("${percent.toStringAsFixed(1)}%"),
  //     ),
  //   );
  // }

  // ---------------------------------------------------
  // CARD COMPONENT
  // ---------------------------------------------------
  Widget _buildCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
