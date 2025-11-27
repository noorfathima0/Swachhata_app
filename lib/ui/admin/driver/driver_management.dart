import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swachhata_app/services/driver_service.dart';
import 'add_driver.dart';
import 'edit_driver.dart';

class AdminDriverManagementPage extends StatelessWidget {
  const AdminDriverManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final driverService = DriverService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Management"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDriverPage()),
          );
        },
        label: const Text("Add Driver"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: driverService.getDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Colors.teal.shade300,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No drivers added yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final drivers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: drivers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = drivers[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    data['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Phone: ${data['phone']} • Age: ${data['age']}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditDriverPage(driverId: doc.id, driverData: data),
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
