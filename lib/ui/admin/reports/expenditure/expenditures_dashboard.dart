import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'expenditure_entry_page.dart';

class ExpenditureDashboardPage extends StatefulWidget {
  const ExpenditureDashboardPage({super.key});

  @override
  State<ExpenditureDashboardPage> createState() =>
      _ExpenditureDashboardPageState();
}

class _ExpenditureDashboardPageState extends State<ExpenditureDashboardPage> {
  bool loading = true;
  DateTime selectedDate = DateTime.now();

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
      });
      loadData();
    }
  }

  bool isSameDay(Timestamp? ts) {
    if (ts == null) return false;
    final d = ts.toDate();
    return d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day;
  }

  Future<void> loadData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("expenditures")
          .orderBy("createdAt", descending: true)
          .get();

      manpower = vehicle = others = revenue = totalExpenditure = 0;

      for (var doc in snap.docs) {
        final d = doc.data();
        if (!isSameDay(d["createdAt"])) continue;

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

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    double netCost = totalExpenditure - revenue;
    final dateText = DateFormat("dd MMM yyyy").format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          "Expenditure Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
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
              padding: const EdgeInsets.all(20),
              children: [
                // --------------------------------------------------
                // HEADER ROW WITH DATE
                // --------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Expenditure Summary",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(dateText),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --------------------------------------------------
                // SUMMARY CARDS
                // --------------------------------------------------
                _summaryCard(
                  icon: Icons.money_off_csred_outlined,
                  title: "Total Expenditure",
                  value: "₹${totalExpenditure.toStringAsFixed(2)}",
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 12),

                _summaryCard(
                  icon: Icons.attach_money_outlined,
                  title: "Revenue (Tax)",
                  value: "₹${revenue.toStringAsFixed(2)}",
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 12),

                _summaryCard(
                  icon: Icons.calculate_outlined,
                  title: "Net Spending",
                  value: "₹${netCost.toStringAsFixed(2)}",
                  color: Colors.blue.shade700,
                ),

                const SizedBox(height: 30),

                // --------------------------------------------------
                // BREAKDOWN TITLE
                // --------------------------------------------------
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.teal.shade700),
                    const SizedBox(width: 10),
                    Text(
                      "Expense Breakdown",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --------------------------------------------------
                // BAR CHART
                // --------------------------------------------------
                Container(
                  height: 260,
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
                  padding: const EdgeInsets.all(16),
                  child: _buildBarChart(),
                ),

                const SizedBox(height: 22),

                _breakdownTile("Manpower", manpower),
                _breakdownTile("Vehicles", vehicle),
                _breakdownTile("Others", others),

                const SizedBox(height: 30),

                // --------------------------------------------------
                // ADD NEW EXPENDITURE BUTTON
                // --------------------------------------------------
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExpenditureEntryPage(),
                      ),
                    ).then((_) => loadData());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add New Expenditure",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ----------------------------------------------------------------------
  // MODERN SUMMARY CARD
  // ----------------------------------------------------------------------
  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // BAR CHART
  // ----------------------------------------------------------------------
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          _bar(0, manpower, Colors.orange),
          _bar(1, vehicle, Colors.blue),
          _bar(2, others, Colors.green),
        ],
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                switch (v.toInt()) {
                  case 0:
                    return const Text("Manpower");
                  case 1:
                    return const Text("Vehicle");
                  case 2:
                    return const Text("Others");
                }
                return const Text("");
              },
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 28,
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // BREAKDOWN TILE
  // ----------------------------------------------------------------------
  Widget _breakdownTile(String title, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
