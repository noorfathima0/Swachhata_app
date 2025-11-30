import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WeighmentEntryPage extends StatefulWidget {
  const WeighmentEntryPage({super.key});

  @override
  State<WeighmentEntryPage> createState() => _WeighmentEntryPageState();
}

class _WeighmentEntryPageState extends State<WeighmentEntryPage> {
  final _formKey = GlobalKey<FormState>();

  String? selectedVehicle;

  final organicCtrl = TextEditingController();
  final dryCtrl = TextEditingController();
  final mixedCtrl = TextEditingController();
  final sanitaryCtrl = TextEditingController();

  List<String> vehicleNumbers = [];

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    final snap = await FirebaseFirestore.instance.collection("vehicles").get();
    vehicleNumbers = snap.docs
        .map((d) => (d.data()["number"] ?? "").toString())
        .toList();
    setState(() {});
  }

  Future<void> saveWeighment() async {
    await FirebaseFirestore.instance.collection("processing_weighments").add({
      "createdAt": FieldValue.serverTimestamp(),
      "vehicleNumber": selectedVehicle ?? "",
      "organicTons": double.tryParse(organicCtrl.text) ?? 0.0,
      "dryTons": double.tryParse(dryCtrl.text) ?? 0.0,
      "mixedTons": double.tryParse(mixedCtrl.text) ?? 0.0,
      "sanitaryTons": double.tryParse(sanitaryCtrl.text) ?? 0.0,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Weighment saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weighment Entry"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: selectedVehicle,
                items: vehicleNumbers
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => selectedVehicle = v),
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? "Select vehicle" : null,
              ),
              const SizedBox(height: 16),

              buildField("Segregated Organic Waste (Tons)", organicCtrl),
              buildField("Segregated Dry Waste (Tons)", dryCtrl),
              buildField("Mixed Waste (Tons)", mixedCtrl),
              buildField("Sanitary Waste (Tons)", sanitaryCtrl),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if ((_formKey.currentState?.validate() ?? false) == true) {
                    saveWeighment();
                  }
                },
                child: const Text("Save Weighment"),
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
