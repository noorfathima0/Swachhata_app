import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'route_follow.dart';

class StartServicePage extends StatelessWidget {
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const StartServicePage({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
  });

  Future<void> startService() async {
    await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(vehicleId)
        .update({
          "status": "running",
          "serviceStartedAt": FieldValue.serverTimestamp(),
          "service": null, // Reset previous service data
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Service"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text(
                  "${vehicleData['type']} - ${vehicleData['number']}",
                ),
                subtitle: Text("Job: ${vehicleData['jobType']}"),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Service"),
              onPressed: () async {
                await startService();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteFollowPage(
                      vehicleId: vehicleId,
                      vehicleData: vehicleData,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
