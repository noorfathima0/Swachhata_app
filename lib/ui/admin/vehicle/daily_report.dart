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
    final formatted = DateFormat("dd MMM yyyy").format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Daily Vehicle Report",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            color: Colors.grey.shade700,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onPressed: _pickDate,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C5F2D)),
            )
          : vehicles.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _headerCard(formatted),

                const SizedBox(height: 20),

                // COLLECTION SUMMARY
                _metricCard(
                  icon: Icons.recycling_rounded,
                  title: "Total Collection Efficiency",
                  color: Colors.blueAccent,
                  percent: _calculateTotalCollectionEfficiency(),
                ),

                const SizedBox(height: 20),

                _sectionTitle("Collection Vehicles", Colors.blueAccent),

                const SizedBox(height: 12),

                ...vehicles.map((v) {
                  final data = v.data() as Map<String, dynamic>;
                  if (data["jobType"] != "collection") return const SizedBox();
                  return _buildCollectionCard(data);
                }),

                const SizedBox(height: 30),

                // SANITATION SUMMARY
                _metricCard(
                  icon: Icons.cleaning_services_rounded,
                  title: "Total Sanitation Efficiency",
                  color: Colors.deepOrangeAccent,
                  percent: _calculateTotalSanitationEfficiency(),
                ),

                const SizedBox(height: 20),

                _sectionTitle("Sanitation Vehicles", Colors.deepOrange),

                const SizedBox(height: 12),

                ...vehicles.map((v) {
                  final data = v.data() as Map<String, dynamic>;
                  if (data["jobType"] != "sanitation") return const SizedBox();

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

  // ---------------------------------------------------------
  //   CALCULATIONS
  // ---------------------------------------------------------

  double _calculateTotalCollectionEfficiency() {
    double total = 0;
    int count = 0;

    for (var v in vehicles) {
      final data = v.data() as Map<String, dynamic>;
      if (data["jobType"] != "collection") continue;

      final service = data["service"];
      if (service == null) continue;

      final start = service["startTime"];
      if (start is! Timestamp) continue;
      if (!_isSameDate(start, selectedDate)) continue;

      final km = (data["km"] ?? 0.0).toDouble();
      final traveled = (service["distanceKm"] ?? 0.0).toDouble();

      if (km > 0) {
        total += (traveled / km) * 100;
        count++;
      }
    }

    return count == 0 ? 0 : total / count;
  }

  double _calculateTotalSanitationEfficiency() {
    double total = 0;
    int count = 0;

    for (var v in vehicles) {
      final data = v.data() as Map<String, dynamic>;
      if (data["jobType"] != "sanitation") continue;

      final service = data["service"];
      if (service == null) continue;

      final start = service["startTime"];
      if (start is! Timestamp) continue;
      if (!_isSameDate(start, selectedDate)) continue;

      if (data["type"] == "jcb") {
        final stops = List<String>.from(data["manualRoute"]?["stops"] ?? []);
        final done = List<String>.from(service["completedStops"] ?? []);

        if (stops.isNotEmpty) {
          total += (done.length / stops.length) * 100;
          count++;
        }
      } else {
        final km = (data["km"] ?? 0.0).toDouble();
        final traveled = (service["distanceKm"] ?? 0.0).toDouble();

        if (km > 0) {
          total += (traveled / km) * 100;
          count++;
        }
      }
    }

    return count == 0 ? 0 : total / count;
  }

  // ---------------------------------------------------------
  //   UI COMPONENTS (FULLY THEMED)
  // ---------------------------------------------------------

  Widget _headerCard(String date) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBubble(Icons.calendar_today_rounded, const Color(0xFF2C5F2D)),
          const SizedBox(width: 16),
          Text(
            "Report for $date",
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

  Widget _metricCard({
    required String title,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBubble(icon, color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "${percent.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Row(
      children: [
        _iconBubble(Icons.directions_bus_rounded, color),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> data) {
    final type = data["type"] ?? "-";
    final number = data["number"] ?? "-";
    final status = data["status"] ?? "idle";

    final service = data["service"];

    if (service == null) {
      return _noReportCard(type, number, status);
    }

    final Timestamp? start = service["startTime"];
    final Timestamp? end = service["endTime"];

    if (start == null || !_isSameDate(start, selectedDate)) {
      return const SizedBox();
    }

    final km = (data["km"] ?? 0.0).toDouble();
    final traveled = (service["distanceKm"] ?? 0.0).toDouble();
    final minutes = (service["durationMinutes"] ?? 0).toInt();

    final percent = km > 0 ? (traveled / km) * 100 : 0.0;

    return _vehicleCard("$type - $number", status, [
      _infoTile("Allotted", "$km KM"),
      _infoTile("Travelled", "${traveled.toStringAsFixed(2)} KM"),
      _progressBar(percent),
      _infoTile("Time", "$minutes min"),
      _infoTile("Start", DateFormat("hh:mm a").format(start.toDate())),
      _infoTile(
        "End",
        end != null ? DateFormat("hh:mm a").format(end.toDate()) : "-",
      ),
    ]);
  }

  Widget _buildJcbCard(Map<String, dynamic> data) {
    final type = data["type"];
    final number = data["number"];
    final status = data["status"];

    final service = data["service"];

    if (service == null) return _noReportCard(type, number, status);

    final Timestamp? start = service["startTime"];
    final Timestamp? end = service["endTime"];

    if (start == null || !_isSameDate(start, selectedDate)) {
      return const SizedBox();
    }

    final stops = List<String>.from(data["manualRoute"]?["stops"] ?? []);
    final done = List<String>.from(service["completedStops"] ?? []);

    final percent = stops.isEmpty ? 0.0 : (done.length / stops.length) * 100;

    return _vehicleCard("$type - $number", status, [
      _infoTile("Stops", "${stops.length}"),
      _infoTile("Completed", "${done.length}"),
      _infoTile("Pending", "${stops.length - done.length}"),
      _progressBar(percent),
      _infoTile("Start", DateFormat("hh:mm a").format(start.toDate())),
      _infoTile(
        "End",
        end != null ? DateFormat("hh:mm a").format(end.toDate()) : "-",
      ),
    ]);
  }

  Widget _vehicleCard(String title, String status, List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 20, runSpacing: 16, children: tiles),
          const SizedBox(height: 16),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _progressBar(double percent) {
    final color = percent >= 80
        ? Colors.green
        : percent >= 40
        ? Colors.orange
        : Colors.red;

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Completed ${percent.toStringAsFixed(1)}%",
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c = Colors.grey;
    if (status == "running") c = Colors.orange;
    if (status == "completed") c = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _iconBubble(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _noReportCard(String type, String number, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$type - $number",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No report available",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.report_gmailerrorred_rounded,
              size: 70,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No vehicles found",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
