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

      // 🔥 Fetch Sales
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
      print("❌ Error loading summary: $e");
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat("dd MMM yyyy").format(selectedDate);

    final totalInput = organic + dry + mixed + sanitary;

    final segregationEff = totalInput == 0 ? 0 : (mixed / totalInput) * 100;

    final totalOutput = compost + recyclable + rdf + inert;
    final processingEff = totalInput == 0
        ? 0
        : (totalOutput / totalInput) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          "Processing Summary",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDate,
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

                // --------------------------------------------------------------
                // PIE CHART CARD
                // --------------------------------------------------------------
                _chartCard(totalInput),

                const SizedBox(height: 26),

                // --------------------------------------------------------------
                // SEGREGATION EFFICIENCY CARD
                // --------------------------------------------------------------
                _efficiencyCard(
                  title: "Segregation Efficiency",
                  value: "${segregationEff.toStringAsFixed(2)}%",
                  color: Colors.deepPurple,
                  icon: Icons.recycling_outlined,
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------------------
                // PROCESSING EFFICIENCY
                // --------------------------------------------------------------
                _efficiencyCard(
                  title: "Processing Efficiency",
                  value: "${processingEff.toStringAsFixed(2)}%",
                  color: Colors.green.shade700,
                  icon: Icons.factory_outlined,
                ),
              ],
            ),
    );
  }

  // --------------------------------------------------------------------
  // PIE CHART WRAPPED IN A BEAUTIFUL CARD
  // --------------------------------------------------------------------
  Widget _chartCard(double totalInput) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.teal.shade700),
              const SizedBox(width: 10),
              Text(
                "Waste Composition",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          totalInput == 0
              ? const Text(
                  "No Processing Data",
                  style: TextStyle(color: Colors.grey),
                )
              : SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        _pieSlice("Organic", organic, totalInput, Colors.green),
                        _pieSlice("Dry", dry, totalInput, Colors.blue),
                        _pieSlice("Mixed", mixed, totalInput, Colors.orange),
                        _pieSlice("Sanitary", sanitary, totalInput, Colors.red),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // BEAUTIFUL PIE SECTION
  // --------------------------------------------------------------------
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
        fontSize: 11,
      ),
    );
  }

  // --------------------------------------------------------------------
  // EFFICIENCY CARD
  // --------------------------------------------------------------------
  Widget _efficiencyCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.15),
            radius: 26,
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
