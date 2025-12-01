import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OverallEfficiencyCard extends StatefulWidget {
  const OverallEfficiencyCard({super.key});

  @override
  State<OverallEfficiencyCard> createState() => _OverallEfficiencyCardState();
}

class _OverallEfficiencyCardState extends State<OverallEfficiencyCard> {
  DateTime selectedDate = DateTime.now();

  double segregationEff = 0;
  double collectionEff = 0;
  double sanitationEff = 0;
  double processingEff = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEfficiency();
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
      loadEfficiency();
    }
  }

  bool isSameDay(Timestamp? ts) {
    if (ts == null) return false;

    final d = ts.toDate();
    return d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day;
  }

  Future<void> loadEfficiency() async {
    try {
      // RESET
      segregationEff = 0;
      collectionEff = 0;
      sanitationEff = 0;
      processingEff = 0;

      // =====================================================================
      //                        COLLECTION + SANITATION
      // =====================================================================
      final vehicles = await FirebaseFirestore.instance
          .collection("vehicles")
          .get();

      double totalCollection = 0;
      int colCount = 0;

      double totalSanitation = 0;
      int sanCount = 0;

      for (var v in vehicles.docs) {
        final data = v.data();
        final service = data["service"];
        if (service == null) continue;

        // FILTER BY DATE
        final Timestamp? startTs = service["startTime"];
        if (!isSameDay(startTs)) continue;

        // COLLECTION
        if (data["jobType"] == "collection") {
          final allotted = (data["km"] ?? 0).toDouble();
          final distance = (service["distanceKm"] ?? 0).toDouble();

          if (allotted > 0) {
            totalCollection += (distance / allotted) * 100;
            colCount++;
          }
        }

        // SANITATION
        if (data["jobType"] == "sanitation") {
          if (data["type"] == "jcb") {
            final stops = (data["manualRoute"]?["stops"] ?? []).length;
            final completed = (service["completedStops"] ?? []).length;

            if (stops > 0) {
              totalSanitation += (completed / stops) * 100;
              sanCount++;
            }
          } else {
            final allotted = (data["km"] ?? 0).toDouble();
            final distance = (service["distanceKm"] ?? 0).toDouble();

            if (allotted > 0) {
              totalSanitation += (distance / allotted) * 100;
              sanCount++;
            }
          }
        }
      }

      collectionEff = colCount == 0 ? 0 : totalCollection / colCount;
      sanitationEff = sanCount == 0 ? 0 : totalSanitation / sanCount;

      // =====================================================================
      //                      SEGREGATION + PROCESSING
      // =====================================================================

      double organic = 0, dry = 0, mixed = 0, sanitary = 0;
      double compost = 0, recyclable = 0, rdf = 0, inert = 0;

      final weighSnap = await FirebaseFirestore.instance
          .collection("processing_weighments")
          .get();

      for (var doc in weighSnap.docs) {
        final d = doc.data();
        if (!isSameDay(d["createdAt"])) continue;

        organic += (d["organicTons"] ?? 0).toDouble();
        dry += (d["dryTons"] ?? 0).toDouble();
        mixed += (d["mixedTons"] ?? 0).toDouble();
        sanitary += (d["sanitaryTons"] ?? 0).toDouble();
      }

      final salesSnap = await FirebaseFirestore.instance
          .collection("processing_sales")
          .get();

      for (var doc in salesSnap.docs) {
        final d = doc.data();
        if (!isSameDay(d["createdAt"])) continue;

        compost += (d["compostTons"] ?? 0).toDouble();
        recyclable += (d["recyclableTons"] ?? 0).toDouble();
        rdf += (d["rdfTons"] ?? 0).toDouble();
        inert += (d["inertTons"] ?? 0).toDouble();
      }

      double totalInput = organic + dry + mixed + sanitary;
      double totalOutput = compost + recyclable + rdf + inert;

      segregationEff = totalInput == 0 ? 0 : (mixed / totalInput) * 100;
      processingEff = totalInput == 0 ? 0 : (totalOutput / totalInput) * 100;
    } catch (e) {
      print("Error calculating efficiency → $e");
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final avg =
        (segregationEff + collectionEff + sanitationEff + processingEff) / 4;

    final dateText = DateFormat("dd MMM yyyy").format(selectedDate);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------------------
                  // 🔥 TITLE + DATE PICKER
                  // ---------------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Overall Efficiency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(dateText),
                        onPressed: pickDate,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ---------------------------------------------------------
                  // 🔥 BAR CHART
                  // ---------------------------------------------------------
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          _bar("Seg", segregationEff, Colors.purple),
                          _bar("Col", collectionEff, Colors.green),
                          _bar("San", sanitationEff, Colors.blue),
                          _bar("Proc", processingEff, Colors.orange),
                        ],
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                switch (v.toInt()) {
                                  case 0:
                                    return const Text("Seg");
                                  case 1:
                                    return const Text("Col");
                                  case 2:
                                    return const Text("San");
                                  case 3:
                                    return const Text("Proc");
                                }
                                return const Text("");
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---------------------------------------------------------
                  // 🔥 AVERAGE EFFICIENCY
                  // ---------------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Total Average Efficiency: ${avg.toStringAsFixed(2)}%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔥 BAR BUILDER FUNCTION
  // ---------------------------------------------------------
  BarChartGroupData _bar(String label, double value, Color color) {
    return BarChartGroupData(
      x: ["Seg", "Col", "San", "Proc"].indexOf(label),
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}
