import 'package:flutter/material.dart';
import 'select_vehicle.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.teal.shade800,
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.4),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Container(),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SelectVehiclePage()),
            );
          },
          child: const Text("Select Vehicle to Start Service"),
        ),
      ),
    );
  }
}
