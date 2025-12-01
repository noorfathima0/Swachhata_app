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
  bool loadingVehicles = true;
  bool saving = false;

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
    setState(() => loadingVehicles = false);
  }

  Future<void> saveWeighment() async {
    setState(() => saving = true);

    await FirebaseFirestore.instance.collection("processing_weighments").add({
      "createdAt": FieldValue.serverTimestamp(),
      "vehicleNumber": selectedVehicle ?? "",
      "organicTons": double.tryParse(organicCtrl.text) ?? 0.0,
      "dryTons": double.tryParse(dryCtrl.text) ?? 0.0,
      "mixedTons": double.tryParse(mixedCtrl.text) ?? 0.0,
      "sanitaryTons": double.tryParse(sanitaryCtrl.text) ?? 0.0,
    });

    setState(() => saving = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Weighment saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text(
          "Weighment Entry",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: loadingVehicles
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // ---------------- VEHICLE CARD ----------------
                    _sectionCard(
                      title: "Vehicle Details",
                      icon: Icons.local_shipping,
                      child: DropdownButtonFormField<String>(
                        value: selectedVehicle,
                        items: vehicleNumbers
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedVehicle = v),
                        decoration: _inputDecoration(
                          "Select Vehicle Number",
                          icon: Icons.local_shipping_outlined,
                        ),
                        validator: (v) =>
                            v == null ? "Please select vehicle" : null,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ---------------- WEIGHMENT CARD ----------------
                    _sectionCard(
                      title: "Waste Categories",
                      icon: Icons.delete_outline,
                      child: Column(
                        children: [
                          _buildField(
                            "Segregated Organic Waste (Tons)",
                            organicCtrl,
                          ),
                          const SizedBox(height: 16),
                          _buildField("Segregated Dry Waste (Tons)", dryCtrl),
                          const SizedBox(height: 16),
                          _buildField("Mixed Waste (Tons)", mixedCtrl),
                          const SizedBox(height: 16),
                          _buildField("Sanitary Waste (Tons)", sanitaryCtrl),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ---------------- SAVE BUTTON ----------------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  saveWeighment();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                height: 23,
                                width: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                "Save Weighment",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --------------------------------------------------------------
  // REUSABLE STYLING COMPONENTS
  // --------------------------------------------------------------

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal.shade700) : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.teal.shade700, size: 22),
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

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}
