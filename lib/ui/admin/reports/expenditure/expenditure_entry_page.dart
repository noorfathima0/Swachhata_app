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

    await FirebaseFirestore.instance.collection("expenditures").add({
      "userId": uid,
      "createdAt": FieldValue.serverTimestamp(),
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
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          "Add Expenditure",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionCard(
                icon: Icons.people_alt,
                title: "Manpower Expenditure",
                children: [
                  _field("PK Wages", pkCtrl),
                  _field("Daily Wages", dailyCtrl),
                  _field("Direct Labors", laborCtrl),
                  _field("Supervisor Wages", supervisorCtrl),
                  _field("Environmental Engineer Salary", envCtrl),
                  _field("Health Inspector Salary", healthCtrl),
                ],
              ),

              const SizedBox(height: 20),

              _sectionCard(
                icon: Icons.local_shipping,
                title: "Vehicle Expenditure",
                children: [
                  _field("Hiring Charges", hireCtrl),
                  _field("Fuel Charges", fuelCtrl),
                  _field("Repair Charges", repairCtrl),
                  _field("Insurance Charges", insuranceCtrl),
                ],
              ),

              const SizedBox(height: 20),

              _sectionCard(
                icon: Icons.inventory,
                title: "Other Expenditures",
                children: [
                  _field("Safety Equipments", safetyCtrl),
                  _field("Consumables", consumableCtrl),
                  _field("Bio Culture", bioCtrl),
                  _field("Power Charges", powerCtrl),
                  _field("Miscellaneous Charges", miscCtrl),
                ],
              ),

              const SizedBox(height: 20),

              _sectionCard(
                icon: Icons.attach_money,
                title: "Revenue",
                children: [_field("Solid Waste Tax Revenue", revenueCtrl)],
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: saveEntry,
                child: const Text(
                  "Save Entry",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // SECTION CARD
  // ------------------------------------------------------------------
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.withOpacity(.15),
                child: Icon(icon, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // TEXT FIELD INPUT
  // ------------------------------------------------------------------
  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}
