import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalesEntryPage extends StatefulWidget {
  const SalesEntryPage({super.key});

  @override
  State<SalesEntryPage> createState() => _SalesEntryPageState();
}

class _SalesEntryPageState extends State<SalesEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final compostCtrl = TextEditingController();
  final compostPriceCtrl = TextEditingController();

  final recycleCtrl = TextEditingController();
  final recyclePriceCtrl = TextEditingController();

  final rdfCtrl = TextEditingController();
  final rdfPriceCtrl = TextEditingController();

  final inertCtrl = TextEditingController();

  bool saving = false;

  double calc(double qty, double rate) => qty * rate;

  Future<void> saveSale() async {
    setState(() => saving = true);

    final compostQty = double.tryParse(compostCtrl.text) ?? 0.0;
    final compostRate = double.tryParse(compostPriceCtrl.text) ?? 0.0;

    final recycleQty = double.tryParse(recycleCtrl.text) ?? 0.0;
    final recycleRate = double.tryParse(recyclePriceCtrl.text) ?? 0.0;

    final rdfQty = double.tryParse(rdfCtrl.text) ?? 0.0;
    final rdfRate = double.tryParse(rdfPriceCtrl.text) ?? 0.0;

    await FirebaseFirestore.instance.collection("processing_sales").add({
      "createdAt": FieldValue.serverTimestamp(),

      "compostTons": compostQty,
      "compostRate": compostRate,
      "compostTotal": calc(compostQty, compostRate),

      "recyclableTons": recycleQty,
      "recyclableRate": recycleRate,
      "recyclableTotal": calc(recycleQty, recycleRate),

      "rdfTons": rdfQty,
      "rdfRate": rdfRate,
      "rdfTotal": calc(rdfQty, rdfRate),

      "inertTons": double.tryParse(inertCtrl.text) ?? 0.0,
    });

    setState(() => saving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Sales entry saved")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text("Sales Entry"),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionCard(
                icon: Icons.grass,
                title: "Compost Sales",
                child: Column(
                  children: [
                    _buildField("Compost Sold (Tons)", compostCtrl),
                    const SizedBox(height: 16),
                    _buildField("Price per Ton (₹)", compostPriceCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _sectionCard(
                icon: Icons.recycling_outlined,
                title: "Recyclables Sales",
                child: Column(
                  children: [
                    _buildField("Recyclables Sold (Tons)", recycleCtrl),
                    const SizedBox(height: 16),
                    _buildField("Price per Ton (₹)", recyclePriceCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _sectionCard(
                icon: Icons.local_fire_department_outlined,
                title: "RDF Sales",
                child: Column(
                  children: [
                    _buildField("RDF Sold (Tons)", rdfCtrl),
                    const SizedBox(height: 16),
                    _buildField("Price per Ton (₹)", rdfPriceCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _sectionCard(
                icon: Icons.terrain_outlined,
                title: "Inert Waste",
                child: _buildField("Inert Waste (Tons)", inertCtrl),
              ),

              const SizedBox(height: 30),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
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

  // -----------------------------------------------------------
  // BEAUTIFUL SECTION CARD
  // -----------------------------------------------------------
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
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
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.teal.shade50,
                child: Icon(icon, color: Colors.teal.shade700, size: 24),
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

  // -----------------------------------------------------------
  // INPUT FIELD WITH THEME
  // -----------------------------------------------------------
  Widget _buildField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.edit_outlined, color: Colors.teal.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
