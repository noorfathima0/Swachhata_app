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
      setState(() {
        selectedDate = picked;
      });
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
    String formattedDate = DateFormat("dd MMM yyyy").format(selectedDate);

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

                  final service = data["service"];
                  final status = (data["status"] ?? "idle").toString();

                  String type = data["type"] ?? "";
                  String number = data["number"] ?? "";

                  if (service == null) {
                    return _buildVehicleCard(
                      type: type,
                      number: number,
                      status: status,
                      distance: 0,
                      time: 0,
                      start: "-",
                      end: "-",
                    );
                  }

                  Timestamp? startTs = service["startTime"];
                  Timestamp? endTs = service["endTime"];

                  if (startTs == null || endTs == null) {
                    return _buildVehicleCard(
                      type: type,
                      number: number,
                      status: status,
                      distance: 0,
                      time: 0,
                      start: "-",
                      end: "-",
                    );
                  }

                  // Only show if this service was done today
                  if (!_isSameDate(startTs, selectedDate)) {
                    return const SizedBox();
                  }

                  double distance = service["distanceKm"] ?? 0.0;
                  int timeMinutes = service["durationMinutes"] ?? 0;

                  String startStr = DateFormat(
                    "hh:mm a",
                  ).format(startTs.toDate());
                  String endStr = DateFormat("hh:mm a").format(endTs.toDate());

                  return _buildVehicleCard(
                    type: type,
                    number: number,
                    status: status,
                    distance: distance,
                    time: timeMinutes,
                    start: startStr,
                    end: endStr,
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildVehicleCard({
    required String type,
    required String number,
    required String status,
    required double distance,
    required int time,
    required String start,
    required String end,
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
              "$type - $number",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoTile("Distance", "${distance.toStringAsFixed(2)} KM"),
                _infoTile("Time", "$time min"),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_infoTile("Start", start), _infoTile("End", end)],
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
