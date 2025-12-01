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

  bool saving = false;

  Future<void> saveEntry() async {
    if (saving) return;
    setState(() => saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in")),
      );
      setState(() => saving = false);
      return;
    }

    await FirebaseFirestore.instance
        .collection("processing_equipment_hours")
        .add({
          "userId": uid,
          "createdAt": FieldValue.serverTimestamp(),
          "screener35": double.tryParse(screen35Ctrl.text) ?? 0.0,
          "screener90": double.tryParse(screen90Ctrl.text) ?? 0.0,
          "screener4": double.tryParse(screen4Ctrl.text) ?? 0.0,
          "balingHours": double.tryParse(balingCtrl.text) ?? 0.0,
        });

    setState(() => saving = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Equipment hours saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          "Equipment Running Hours",
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
                title: "Machine Hours Entry",
                icon: Icons.precision_manufacturing_outlined,
                child: Column(
                  children: [
                    _buildField("Screener 35mm (Hours)", screen35Ctrl),
                    const SizedBox(height: 16),
                    _buildField("Screener 90mm (Hours)", screen90Ctrl),
                    const SizedBox(height: 16),
                    _buildField("Screener 4mm (Hours)", screen4Ctrl),
                    const SizedBox(height: 16),
                    _buildField("Baling Machine (Hours)", balingCtrl),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            saveEntry();
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
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Save Entry",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
  // BEAUTIFUL INPUT FIELD
  // --------------------------------------------------------------
  Widget _buildField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(Icons.timer_outlined, color: Colors.teal.shade700),
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

  // --------------------------------------------------------------
  // SECTION CARD
  // --------------------------------------------------------------
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
          // ---- Header Row ----
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
