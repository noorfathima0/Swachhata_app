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
      builder: (context, child) =>
          Theme(data: ThemeData.light(), child: child!),
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
                const SizedBox(height: 12),

                ...vehicles.map((v) {
                  final data = v.data() as Map<String, dynamic>;

                  final allottedKm = (data["km"] ?? 0.0).toDouble();

                  final service =
                      data["service"]; // stored after driver completes
                  final status = (data["status"] ?? "idle").toString();

                  final type = data["type"] ?? "";
                  final number = data["number"] ?? "";

                  if (service == null) {
                    return _buildVehicleCard(
                      type: type,
                      number: number,
                      status: status,
                      allottedKm: allottedKm,
                      distance: 0,
                      percent: 0,
                      time: 0,
                      start: "-",
                      end: "-",
                    );
                  }

                  final Timestamp? startTs = service["startTime"];
                  final Timestamp? endTs = service["endTime"];

                  if (startTs == null ||
                      endTs == null ||
                      !_isSameDate(startTs, selectedDate)) {
                    return const SizedBox();
                  }

                  final traveledKm = (service["distanceKm"] ?? 0.0).toDouble();

                  final timeMinutes = (service["durationMinutes"] ?? 0).toInt();

                  final percent = allottedKm > 0
                      ? (traveledKm / allottedKm) * 100
                      : 0.0;

                  final startStr = DateFormat(
                    "hh:mm a",
                  ).format(startTs.toDate());
                  final endStr = DateFormat("hh:mm a").format(endTs.toDate());

                  return _buildVehicleCard(
                    type: type,
                    number: number,
                    status: status,
                    allottedKm: allottedKm,
                    distance: traveledKm,
                    percent: percent,
                    time: timeMinutes,
                    start: startStr,
                    end: endStr,
                  );
                }),
              ],
            ),
    );
  }

  // ---------------- VEHICLE CARD ----------------
  Widget _buildVehicleCard({
    required String type,
    required String number,
    required String status,
    required double allottedKm,
    required double distance,
    required double percent,
    required int time,
    required String start,
    required String end,
  }) {
    Color percentColor = percent >= 80
        ? Colors.green
        : percent >= 40
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VEHICLE TITLE
            Text(
              "$type - $number",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // ALLOTTED & TRAVELLED
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoTile("Allotted KM", allottedKm.toStringAsFixed(2)),
                _infoTile("Travelled", "${distance.toStringAsFixed(2)} KM"),
              ],
            ),

            const SizedBox(height: 12),

            // 🔥 Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Completed: ${percent.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: percentColor,
                    fontWeight: FontWeight.bold,
                  ),
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

            const SizedBox(height: 12),

            // TIME & START-END
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoTile("Time", "$time min"),
                _infoTile("Start", start),
                _infoTile("End", end),
              ],
            ),

            const SizedBox(height: 12),

            // STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == "completed"
                    ? Colors.green.withOpacity(.2)
                    : status == "running"
                    ? Colors.orange.withOpacity(.2)
                    : Colors.grey.withOpacity(.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: status == "completed"
                      ? Colors.green
                      : status == "running"
                      ? Colors.orange
                      : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SMALL TILE ----------------
  Widget _infoTile(String title, String value) {
    return Column(
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
    );
  }
}
