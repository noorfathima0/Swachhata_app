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
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'idle':
      default:
        return Colors.blueGrey;
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
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text(
          'Vehicle Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,

        actions: [
          // 🔥 NEW — FULL VEHICLE REPORT BUTTON
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: "View Vehicle Daily Reports",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDailyReportPage()),
              );
            },
          ),

          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: "Live Vehicle Tracking",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminLiveVehicleTrackingPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: vehicleService.getVehicles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red[700]),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.teal[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No vehicles added yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add a new vehicle.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final doc = vehicles[index];
              final data = doc.data() as Map<String, dynamic>;

              final type = data['type'] ?? '';
              final number = data['number'] ?? '';
              final jobType = data['jobType'] ?? '';
              final status = data['status'] ?? 'idle';
              final routeType = data['routeType'] ?? '';
              final manualRoute = (data['manualRoute'] ?? '').toString();

              String routeLabel;
              if (routeType == 'manual' && manualRoute.isNotEmpty) {
                routeLabel = manualRoute;
              } else if (routeType == 'map') {
                routeLabel = 'Map route selected';
              } else {
                routeLabel = 'No route set';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.teal.withOpacity(0.1),
                    child: Icon(_vehicleIcon(type), color: Colors.teal),
                  ),
                  title: Text(
                    '$type - $number',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job: ${jobType.isEmpty ? 'N/A' : jobType}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Route: $routeLabel',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor(status), width: 1),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVehiclePage()),
          );
        },
      ),
    );
  }
}
