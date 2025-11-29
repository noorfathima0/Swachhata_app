import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'start_service.dart';

class SelectVehiclePage extends StatelessWidget {
  const SelectVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Vehicle"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("vehicles").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vehicles.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final doc = vehicles[index];
              final data = doc.data() as Map<String, dynamic>;

              final String type = (data['type'] ?? "").toString();
              final String number = (data['number'] ?? "").toString();
              final String jobType = (data['jobType'] ?? "").toString();
              final String routeType = (data['routeType'] ?? "").toString();
              final String status = (data['status'] ?? "idle").toString();

              final bool inUse = status == "running";

              // -------- Route Label logic (matches Admin UI) --------
              String routeLabel = "No route set";

              if (type == "jcb" && routeType == "jcb_stops") {
                final stops = (data['manualRoute']?['stops'] ?? []) as List;
                routeLabel = "JCB Stops: ${stops.length} stops";
              } else if (routeType == "manual") {
                final start = data['manualRoute']?['start'] ?? "";
                final end = data['manualRoute']?['end'] ?? "";
                routeLabel = "$start → $end";
              } else if (routeType == "map") {
                routeLabel = "Map route selected";
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  title: Text("${type.toUpperCase()} - $number"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Work: ${jobType.toUpperCase()}"),
                      Text("Route: $routeLabel"),
                    ],
                  ),

                  // BADGE
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: inUse
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inUse ? "IN USE" : "AVAILABLE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: inUse ? Colors.red : Colors.green,
                      ),
                    ),
                  ),

                  // DISABLE TAP IF IN USE
                  onTap: inUse
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "This vehicle is currently in use.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StartServicePage(
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
    );
  }
}
