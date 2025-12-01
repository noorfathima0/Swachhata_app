import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swachhata_app/services/vehicle_service.dart';
import 'add_vehicle.dart';
import 'edit_vehicle.dart';
import 'daily_report.dart';
import 'live_vehicle_map.dart';

class AdminVehicleManagementPage extends StatelessWidget {
  const AdminVehicleManagementPage({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
        return Color(0xFFE67E22);
      case 'completed':
        return Color(0xFF27AE60);
      case 'idle':
      default:
        return Color(0xFF7F8C8D);
    }
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'auto':
        return Icons.local_taxi;
      case 'tipper':
        return Icons.local_shipping;
      case 'tractor':
        return Icons.agriculture;
      case 'jcb':
        return Icons.construction;
      default:
        return Icons.directions_bus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicleService = VehicleService();

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Vehicle Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.table_chart_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDailyReportPage(),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.map_rounded, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLiveVehicleTrackingPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: vehicleService.getVehicles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading Vehicles...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 70,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "No Vehicles Added",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Add your first vehicle to start tracking and managing fleet operations.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final vehicles = snapshot.data!.docs;

          return Padding(
            padding: EdgeInsets.all(20),
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final doc = vehicles[index];
                final data = doc.data() as Map<String, dynamic>;

                final status = data['status'] ?? 'idle';
                final type = data['type'] ?? '';
                final number = data['number'] ?? '';
                final jobType = data['jobType'] ?? '';
                final routeType = data['routeType'] ?? '';
                final manualRoute = (data['manualRoute'] ?? '').toString();

                // 🔥 AUTO RESET COMPLETED TO IDLE AFTER 12 HOURS
                if (status == "completed" && data['completedAt'] != null) {
                  final completedAt = (data['completedAt'] as Timestamp)
                      .toDate();
                  final now = DateTime.now();
                  final difference = now.difference(completedAt);

                  if (difference.inHours >= 12) {
                    FirebaseFirestore.instance
                        .collection("vehicles")
                        .doc(doc.id)
                        .update({"status": "idle"});
                  }
                }

                String routeLabel;
                if (routeType == 'manual' && manualRoute.isNotEmpty) {
                  routeLabel = manualRoute;
                } else if (routeType == 'map') {
                  routeLabel = 'Map route selected';
                } else {
                  routeLabel = 'No route set';
                }

                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditVehiclePage(
                              vehicleId: doc.id,
                              vehicleData: data,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // 🚗 Vehicle Icon
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Color(0xFF2C5F2D).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _vehicleIcon(type),
                                color: Color(0xFF2C5F2D),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),

                            // 📝 Vehicle Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$type - $number',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                            color: Colors.grey.shade800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              _statusColor(status),
                                              _statusColor(
                                                status,
                                              ).withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.work_outline_rounded,
                                          color: Colors.orange.shade600,
                                          size: 14,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Job: ${jobType.isEmpty ? 'N/A' : jobType}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.route_rounded,
                                          color: Colors.blue.shade600,
                                          size: 14,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          routeLabel,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Spacer(),
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.grey.shade600,
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 20, right: 20),
        child: FloatingActionButton.extended(
          backgroundColor: Color(0xFF2C5F2D),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(Icons.add_rounded),
          label: Text(
            'Add Vehicle',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddVehiclePage()),
            );
          },
        ),
      ),
    );
  }
}
