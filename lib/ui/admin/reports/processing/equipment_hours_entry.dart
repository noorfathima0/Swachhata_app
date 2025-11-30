import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EquipmentHoursEntryPage extends StatefulWidget {
  const EquipmentHoursEntryPage({super.key});

  @override
  State<EquipmentHoursEntryPage> createState() =>
      _EquipmentHoursEntryPageState();
}

class _EquipmentHoursEntryPageState extends State<EquipmentHoursEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final screen35Ctrl = TextEditingController();
  final screen90Ctrl = TextEditingController();
  final screen4Ctrl = TextEditingController();
  final balingCtrl = TextEditingController();

  Future<void> saveEntry() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("processing_equipment_hours") // Main collection
        .add({
          "userId": uid, // Store user ID as a field
          "createdAt": FieldValue.serverTimestamp(),
          "screener35": double.tryParse(screen35Ctrl.text) ?? 0.0,
          "screener90": double.tryParse(screen90Ctrl.text) ?? 0.0,
          "screener4": double.tryParse(screen4Ctrl.text) ?? 0.0,
          "balingHours": double.tryParse(balingCtrl.text) ?? 0.0,
        });

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Equipment hours saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipment Running Hours"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildField("Screener 35mm (Hours)", screen35Ctrl),
              buildField("Screener 90mm (Hours)", screen90Ctrl),
              buildField("Screener 4mm (Hours)", screen4Ctrl),
              buildField("Baling Machine (Hours)", balingCtrl),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveEntry,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
