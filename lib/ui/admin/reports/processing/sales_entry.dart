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

  double calc(double qty, double rate) => qty * rate;

  Future<void> saveSale() async {
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

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Sales entry saved")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Entry"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              title("Compost"),
              buildField("Compost Sales (Tons)", compostCtrl),
              buildField("Price per Ton", compostPriceCtrl),

              title("Recyclables"),
              buildField("Recyclable Sales (Tons)", recycleCtrl),
              buildField("Price per Ton", recyclePriceCtrl),

              title("RDF"),
              buildField("RDF Sales (Tons)", rdfCtrl),
              buildField("Price per Ton", rdfPriceCtrl),

              title("Inert Waste"),
              buildField("Inert Waste Landfilling (Tons)", inertCtrl),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveSale,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget title(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    ),
  );

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
