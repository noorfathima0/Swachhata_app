import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDailyReportPage extends StatefulWidget {
  const AdminDailyReportPage({super.key});

  @override
  State<AdminDailyReportPage> createState() => _AdminDailyReportPageState();
}

class _AdminDailyReportPageState extends State<AdminDailyReportPage> {
  DateTime selectedDate = DateTime.now();
  bool loading = false;

  List<QueryDocumentSnapshot> vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    setState(() => loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection("vehicles")
        .get();

    vehicles = snapshot.docs;

    setState(() => loading = false);
  }

  bool _isSameDate(Timestamp ts, DateTime date) {
    final d = ts.toDate();
    return d.year == date.year && d.month == date.month && d.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat("dd MMM yyyy").format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Vehicle Report"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : vehicles.isEmpty
          ? const Center(child: Text("No vehicles found"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  "Report for $formattedDate",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // ============================================
                //     🔵 TOTAL COLLECTION EFFICIENCY
                // ============================================
                _buildTotalEfficiencyCard(
                  title: "Total Collection Efficiency",
                  percent: _calculateTotalCollectionEfficiency(),
                  color: Colors.blueGrey,
                ),

                const SizedBox(height: 10),

                // ---------------- COLLECTION SECTION ----------------
                const Text(
                  "Collection Vehicles",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 10),

                ...vehicles.map((v) {
                  final data = v.data() as Map<String, dynamic>;

                  if (data["jobType"] != "collection") {
                    return const SizedBox();
                  }

                  return _buildCollectionCard(data);
                }),

                const SizedBox(height: 25),

                // ============================================
                //     🟠 TOTAL SANITATION EFFICIENCY
                // ============================================
                _buildTotalEfficiencyCard(
                  title: "Total Sanitation Efficiency",
                  percent: _calculateTotalSanitationEfficiency(),
                  color: Colors.deepOrange,
                ),

                const SizedBox(height: 10),

                // ---------------- SANITATION SECTION ----------------
                const Text(
                  "Sanitation Vehicles",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 10),

                ...vehicles.map((v) {
                  final data = v.data() as Map<String, dynamic>;

                  if (data["jobType"] != "sanitation") {
                    return const SizedBox();
                  }

                  if (data["type"] == "jcb") {
                    return _buildJcbCard(data);
                  } else {
                    return _buildCollectionCard(data);
                  }
                }),
              ],
            ),
    );
  }

  // =====================================================
  //     🔵 TOTAL COLLECTION EFFICIENCY CALCULATION
  // =====================================================
  double _calculateTotalCollectionEfficiency() {
    double total = 0;
    int count = 0;

    for (var v in vehicles) {
      final data = v.data() as Map<String, dynamic>;
      if (data["jobType"] != "collection") continue;

      final service = data["service"];
      if (service == null) continue;

      final startTs = service["startTime"];
      if (startTs is! Timestamp) continue;
      if (!_isSameDate(startTs, selectedDate)) continue;

      final allottedKm = (data["km"] ?? 0.0).toDouble();
      final traveledKm = (service["distanceKm"] ?? 0.0).toDouble();

      if (allottedKm > 0) {
        final percent = (traveledKm / allottedKm) * 100;
        total += percent;
        count++;
      }
    }

    return count == 0 ? 0 : total / count;
  }

  // =====================================================
  //     🟠 TOTAL SANITATION EFFICIENCY CALCULATION
  // =====================================================
  double _calculateTotalSanitationEfficiency() {
    double total = 0;
    int count = 0;

    for (var v in vehicles) {
      final data = v.data() as Map<String, dynamic>;

      if (data["jobType"] != "sanitation") continue;

      final service = data["service"];
      if (service == null) continue;

      final startTs = service["startTime"];
      if (startTs is! Timestamp) continue;
      if (!_isSameDate(startTs, selectedDate)) continue;

      if (data["type"] == "jcb") {
        // JCB — stop-based
        final stops = (data["manualRoute"]?["stops"] ?? []) as List;
        final completed = (service["completedStops"] ?? []) as List;
        if (stops.isNotEmpty) {
          total += (completed.length / stops.length) * 100;
          count++;
        }
      } else {
        // Tractor — KM-based
        final allottedKm = (data["km"] ?? 0.0).toDouble();
        final traveledKm = (service["distanceKm"] ?? 0.0).toDouble();
        if (allottedKm > 0) {
          total += (traveledKm / allottedKm) * 100;
          count++;
        }
      }
    }

    return count == 0 ? 0 : total / count;
  }

  // =====================================================
  //          TOTAL EFFICIENCY CARD UI
  // =====================================================
  Widget _buildTotalEfficiencyCard({
    required String title,
    required double percent,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 6),
            Text(
              "${percent.toStringAsFixed(1)}%",
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

  // ---------------- COLLECTION CARD ----------------
  Widget _buildCollectionCard(Map<String, dynamic> data) {
    final type = (data["type"] ?? "Unknown").toString();
    final number = (data["number"] ?? "Unknown").toString();
    final status = (data["status"] ?? "idle").toString();

    final allottedKm = (data["km"] ?? 0.0).toDouble();

    final service = data["service"];
    if (service == null) {
      return _noReportCard(type, number, status);
    }

    final Timestamp? startTs = service["startTime"] is Timestamp
        ? service["startTime"]
        : null;
    final Timestamp? endTs = service["endTime"] is Timestamp
        ? service["endTime"]
        : null;

    if (startTs == null || !_isSameDate(startTs, selectedDate)) {
      return const SizedBox();
    }

    final traveledKm = (service["distanceKm"] ?? 0.0).toDouble();
    final timeMinutes = (service["durationMinutes"] ?? 0).toInt();

    final percent = allottedKm > 0 ? (traveledKm / allottedKm) * 100 : 0.0;

    return _vehicleCard(
      title: "$type - $number",
      status: status,
      tiles: [
        _infoTile("Allotted KM", allottedKm.toStringAsFixed(2)),
        _infoTile("Travelled", "${traveledKm.toStringAsFixed(2)} KM"),
        _progressBar(percent),
        _infoTile("Time", "$timeMinutes min"),
        _infoTile(
          "Start",
          startTs != null
              ? DateFormat("hh:mm a").format(startTs.toDate())
              : "-",
        ),
        _infoTile(
          "End",
          endTs != null ? DateFormat("hh:mm a").format(endTs.toDate()) : "-",
        ),
      ],
    );
  }

  // ---------------- JCB REPORT CARD ----------------
  Widget _buildJcbCard(Map<String, dynamic> data) {
    final type = (data["type"] ?? "Unknown").toString();
    final number = (data["number"] ?? "Unknown").toString();
    final status = (data["status"] ?? "idle").toString();

    final service = data["service"];
    if (service == null) return _noReportCard(type, number, status);

    final Timestamp? startTs = service["startTime"] is Timestamp
        ? service["startTime"]
        : null;
    final Timestamp? endTs = service["endTime"] is Timestamp
        ? service["endTime"]
        : null;

    if (startTs == null || !_isSameDate(startTs, selectedDate)) {
      return const SizedBox();
    }

    final stops = (data["manualRoute"]?["stops"] ?? []) is List
        ? data["manualRoute"]["stops"].cast<String>()
        : <String>[];
    final completed = (service["completedStops"] ?? []) is List
        ? service["completedStops"].cast<String>()
        : <String>[];

    final total = stops.length;
    final done = completed.length;
    final percent = total > 0 ? (done / total) * 100 : 0.0;

    return _vehicleCard(
      title: "$type - $number",
      status: status,
      tiles: [
        _infoTile("Total Stops", total.toString()),
        _infoTile("Completed", done.toString()),
        _infoTile("Pending", (total - done).toString()),
        _progressBar(percent),
        _infoTile(
          "Start",
          startTs != null
              ? DateFormat("hh:mm a").format(startTs.toDate())
              : "-",
        ),
        _infoTile(
          "End",
          endTs != null ? DateFormat("hh:mm a").format(endTs.toDate()) : "-",
        ),
      ],
    );
  }

  // ---------------- REUSABLE CARD UI ----------------
  Widget _vehicleCard({
    required String title,
    required String status,
    required List<Widget> tiles,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 20, runSpacing: 10, children: tiles),
            const SizedBox(height: 12),
            _statusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(double percent) {
    Color percentColor = percent >= 80
        ? Colors.green
        : percent >= 40
        ? Colors.orange
        : Colors.red;

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Completed: ${percent.toStringAsFixed(1)}%",
            style: TextStyle(color: percentColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade300,
              color: percentColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATUS BADGE ----------------
  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status == "completed") color = Colors.green;
    if (status == "running") color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ---------------- NO REPORT CARD ----------------
  Widget _noReportCard(String type, String number, String status) {
    return _vehicleCard(
      title: "$type - $number",
      status: status,
      tiles: [_infoTile("No Report", "-")],
    );
  }

  // ---------------- SMALL TILE ----------------
  Widget _infoTile(String title, String value) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
