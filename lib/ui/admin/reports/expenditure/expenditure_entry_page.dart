import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenditureEntryPage extends StatefulWidget {
  const ExpenditureEntryPage({super.key});

  @override
  State<ExpenditureEntryPage> createState() => _ExpenditureEntryPageState();
}

class _ExpenditureEntryPageState extends State<ExpenditureEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // MANPOWER
  final pkCtrl = TextEditingController();
  final dailyCtrl = TextEditingController();
  final laborCtrl = TextEditingController();
  final supervisorCtrl = TextEditingController();
  final envCtrl = TextEditingController();
  final healthCtrl = TextEditingController();

  // VEHICLE
  final hireCtrl = TextEditingController();
  final fuelCtrl = TextEditingController();
  final repairCtrl = TextEditingController();
  final insuranceCtrl = TextEditingController();

  // OTHERS
  final safetyCtrl = TextEditingController();
  final consumableCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final powerCtrl = TextEditingController();
  final miscCtrl = TextEditingController();

  // REVENUE
  final revenueCtrl = TextEditingController();

  Future<void> saveEntry() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    double manpower =
        (double.tryParse(pkCtrl.text) ?? 0) +
        (double.tryParse(dailyCtrl.text) ?? 0) +
        (double.tryParse(laborCtrl.text) ?? 0) +
        (double.tryParse(supervisorCtrl.text) ?? 0) +
        (double.tryParse(envCtrl.text) ?? 0) +
        (double.tryParse(healthCtrl.text) ?? 0);

    double vehicle =
        (double.tryParse(hireCtrl.text) ?? 0) +
        (double.tryParse(fuelCtrl.text) ?? 0) +
        (double.tryParse(repairCtrl.text) ?? 0) +
        (double.tryParse(insuranceCtrl.text) ?? 0);

    double others =
        (double.tryParse(safetyCtrl.text) ?? 0) +
        (double.tryParse(consumableCtrl.text) ?? 0) +
        (double.tryParse(bioCtrl.text) ?? 0) +
        (double.tryParse(powerCtrl.text) ?? 0) +
        (double.tryParse(miscCtrl.text) ?? 0);

    double revenue = double.tryParse(revenueCtrl.text) ?? 0;

    double totalExp = manpower + vehicle + others;

    // CHANGED: Write to main collection instead of user subcollection
    await FirebaseFirestore.instance
        .collection("expenditures") // Main collection
        .add({
          "userId": uid, // Store user ID as a field
          "createdAt": FieldValue.serverTimestamp(), // Use server timestamp
          "pkWages": double.tryParse(pkCtrl.text) ?? 0,
          "dailyWages": double.tryParse(dailyCtrl.text) ?? 0,
          "directLabors": double.tryParse(laborCtrl.text) ?? 0,
          "supervisorWages": double.tryParse(supervisorCtrl.text) ?? 0,
          "envEngineer": double.tryParse(envCtrl.text) ?? 0,
          "healthInspector": double.tryParse(healthCtrl.text) ?? 0,
          "hiringCharges": double.tryParse(hireCtrl.text) ?? 0,
          "fuelCharges": double.tryParse(fuelCtrl.text) ?? 0,
          "repairCharges": double.tryParse(repairCtrl.text) ?? 0,
          "insuranceCharges": double.tryParse(insuranceCtrl.text) ?? 0,
          "safetyEquip": double.tryParse(safetyCtrl.text) ?? 0,
          "consumables": double.tryParse(consumableCtrl.text) ?? 0,
          "bioCulture": double.tryParse(bioCtrl.text) ?? 0,
          "powerCharges": double.tryParse(powerCtrl.text) ?? 0,
          "miscCharges": double.tryParse(miscCtrl.text) ?? 0,
          "taxRevenue": revenue,
          "totalExpenditure": totalExp,
        });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expenditure saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Expenditure"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _heading("Manpower Expenditure"),
              _field("PK Wages", pkCtrl),
              _field("Daily Wages", dailyCtrl),
              _field("Direct Labors", laborCtrl),
              _field("Supervisor Wages", supervisorCtrl),
              _field("Environmental Engineer Salary", envCtrl),
              _field("Health Inspector Salary", healthCtrl),

              const SizedBox(height: 20),
              _heading("Vehicle Expenditure"),
              _field("Hiring Charges", hireCtrl),
              _field("Fuel Charges", fuelCtrl),
              _field("Repair Charges", repairCtrl),
              _field("Insurance Charges", insuranceCtrl),

              const SizedBox(height: 20),
              _heading("Other Expenditures"),
              _field("Safety Equipments", safetyCtrl),
              _field("Consumables", consumableCtrl),
              _field("Bio Culture", bioCtrl),
              _field("Power Charges", powerCtrl),
              _field("Miscellaneous Charges", miscCtrl),

              const SizedBox(height: 20),
              _heading("Revenue"),
              _field("Solid Waste Tax Revenue", revenueCtrl),

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: saveEntry,
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
