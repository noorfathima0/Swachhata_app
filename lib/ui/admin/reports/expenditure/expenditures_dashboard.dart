import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'expenditure_entry_page.dart';

class ExpenditureDashboardPage extends StatefulWidget {
  const ExpenditureDashboardPage({super.key});

  @override
  State<ExpenditureDashboardPage> createState() =>
      _ExpenditureDashboardPageState();
}

class _ExpenditureDashboardPageState extends State<ExpenditureDashboardPage> {
  bool loading = true;

  double manpower = 0;
  double vehicle = 0;
  double others = 0;
  double revenue = 0;
  double totalExpenditure = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("expenditures")
          .orderBy("createdAt", descending: true)
          .get();

      manpower = 0;
      vehicle = 0;
      others = 0;
      revenue = 0;
      totalExpenditure = 0;

      for (var doc in snap.docs) {
        final d = doc.data();

        manpower +=
            (d["pkWages"] ?? 0) +
            (d["dailyWages"] ?? 0) +
            (d["directLabors"] ?? 0) +
            (d["supervisorWages"] ?? 0) +
            (d["envEngineer"] ?? 0) +
            (d["healthInspector"] ?? 0);

        vehicle +=
            (d["hiringCharges"] ?? 0) +
            (d["fuelCharges"] ?? 0) +
            (d["repairCharges"] ?? 0) +
            (d["insuranceCharges"] ?? 0);

        others +=
            (d["safetyEquip"] ?? 0) +
            (d["consumables"] ?? 0) +
            (d["bioCulture"] ?? 0) +
            (d["powerCharges"] ?? 0) +
            (d["miscCharges"] ?? 0);

        revenue += (d["taxRevenue"] ?? 0);
        totalExpenditure += (d["totalExpenditure"] ?? 0);
      }
    } catch (e) {
      print("❌ Error loading dashboard: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    double costPerTon = totalExpenditure == 0 ? 0 : totalExpenditure - revenue;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenditure Dashboard"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenditureEntryPage()),
              ).then((_) => loadData());
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle("Expenditure Summary"),
                _summaryCard(
                  "Total Expenditure",
                  "₹${totalExpenditure.toStringAsFixed(2)}",
                  Colors.red,
                ),
                _summaryCard(
                  "Revenue (Tax)",
                  "₹${revenue.toStringAsFixed(2)}",
                  Colors.green,
                ),
                _summaryCard(
                  "Net Spending (Cost per ton)",
                  "₹${costPerTon.toStringAsFixed(2)}",
                  Colors.blue,
                ),

                const SizedBox(height: 20),
                _sectionTitle("Breakdown"),

                SizedBox(height: 250, child: _buildBarChart()),

                _breakdownTile("Manpower", manpower),
                _breakdownTile("Vehicle Expenses", vehicle),
                _breakdownTile("Other Expenses", others),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenditureEntryPage(),
                      ),
                    ).then((_) => loadData());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Expenditure"),
                ),
              ],
            ),
    );
  }

  // SECTION TITLE
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  // SUMMARY CARD
  Widget _summaryCard(String title, String value, Color color) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BAR CHART
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          _bar("Manpower", manpower, Colors.orange),
          _bar("Vehicle", vehicle, Colors.blue),
          _bar("Others", others, Colors.green),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                switch (v.toInt()) {
                  case 0:
                    return const Text("Manpower");
                  case 1:
                    return const Text("Vehicle");
                  case 2:
                    return const Text("Others");
                  default:
                    return const Text("");
                }
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  BarChartGroupData _bar(String name, double value, Color c) {
    return BarChartGroupData(
      x: name == "Manpower"
          ? 0
          : name == "Vehicle"
          ? 1
          : 2,
      barRods: [
        BarChartRodData(
          toY: value,
          color: c,
          width: 30,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // BREAKDOWN TILE
  Widget _breakdownTile(String name, double value) {
    return Card(
      child: ListTile(
        title: Text(name),
        trailing: Text("₹${value.toStringAsFixed(2)}"),
      ),
    );
  }
}
