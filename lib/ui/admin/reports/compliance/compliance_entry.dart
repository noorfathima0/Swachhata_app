import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:swachhata_app/services/imgbb_service.dart';

class ComplianceEntryPage extends StatefulWidget {
  final String? docId; // Null = add new, has value = edit
  final Map<String, dynamic>? existingData;

  const ComplianceEntryPage({super.key, this.docId, this.existingData});

  @override
  State<ComplianceEntryPage> createState() => _ComplianceEntryPageState();
}

class _ComplianceEntryPageState extends State<ComplianceEntryPage> {
  final vehicleCtrl = TextEditingController();

  DateTime? insuranceStart, insuranceEnd, renewalDue;
  DateTime? pollutionRenew, laborInsurance, fcDue;

  String? pollutionUrl;
  String? laborUrl;
  String? fcUrl;

  final ImgBBService imgbb = ImgBBService();

  @override
  void initState() {
    super.initState();

    if (widget.existingData != null) _loadExisting();
  }

  void _loadExisting() {
    final d = widget.existingData!;

    vehicleCtrl.text = d["vehicleNumber"] ?? "";

    insuranceStart = _toDate(d["insuranceStart"]);
    insuranceEnd = _toDate(d["insuranceEnd"]);
    renewalDue = _toDate(d["renewalDue"]);
    pollutionRenew = _toDate(d["pollutionRenew"]);
    laborInsurance = _toDate(d["laborInsurance"]);
    fcDue = _toDate(d["fcDue"]);

    pollutionUrl = d["pollutionFile"];
    laborUrl = d["laborFile"];
    fcUrl = d["fcFile"];
  }

  DateTime? _toDate(dynamic t) {
    if (t is Timestamp) return t.toDate();
    return null;
  }

  // PICK DATE
  Future<void> pickDate(Function(DateTime) onPicked) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );
    if (d != null) onPicked(d);
    setState(() {});
  }

  // FILE UPLOAD
  Future<String?> uploadFile() async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    if (pick == null) return null;

    final file = File(pick.files.first.path!);
    return await imgbb.uploadImage(file);
  }

  // SAVE OR UPDATE
  Future<void> saveEntry() async {
    final data = {
      "vehicleNumber": vehicleCtrl.text,
      "insuranceStart": insuranceStart,
      "insuranceEnd": insuranceEnd,
      "renewalDue": renewalDue,
      "pollutionRenew": pollutionRenew,
      "laborInsurance": laborInsurance,
      "fcDue": fcDue,
      "pollutionFile": pollutionUrl,
      "laborFile": laborUrl,
      "fcFile": fcUrl,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (widget.docId == null) {
      data["createdAt"] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection("compliance").add(data);
    } else {
      await FirebaseFirestore.instance
          .collection("compliance")
          .doc(widget.docId)
          .update(data);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.docId == null
              ? "Compliance added successfully"
              : "Compliance updated successfully",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? "Edit Compliance" : "Add Compliance"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field("Vehicle Number", vehicleCtrl),

          _dateField(
            "Insurance Start Date",
            insuranceStart,
            (d) => insuranceStart = d,
          ),
          _dateField(
            "Insurance End Date",
            insuranceEnd,
            (d) => insuranceEnd = d,
          ),
          _dateField("Renewal Due Date", renewalDue, (d) => renewalDue = d),
          _dateField(
            "Pollution Licence Renewal",
            pollutionRenew,
            (d) => pollutionRenew = d,
          ),
          _dateField(
            "Labor Insurance Renewal",
            laborInsurance,
            (d) => laborInsurance = d,
          ),
          _dateField("Vehicle FC Due Date", fcDue, (d) => fcDue = d),

          const SizedBox(height: 15),

          _uploadButton(
            "Upload Pollution Document",
            pollutionUrl,
            (url) => pollutionUrl = url,
          ),
          _uploadButton(
            "Upload Labor Insurance Document",
            laborUrl,
            (url) => laborUrl = url,
          ),
          _uploadButton("Upload FC Certificate", fcUrl, (url) => fcUrl = url),

          const SizedBox(height: 25),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: saveEntry,
            child: Text(editing ? "Update" : "Save"),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, Function(DateTime) pick) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        value == null ? "Select Date" : value.toString().split(" ").first,
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () => pickDate(pick),
    );
  }

  Widget _uploadButton(String label, String? url, Function(String) onUploaded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: Text(label),
          onPressed: () async {
            final uploaded = await uploadFile();
            if (uploaded != null) {
              onUploaded(uploaded);
              setState(() {});
            }
          },
        ),
        if (url != null)
          Text("Uploaded ✔️", style: const TextStyle(color: Colors.green)),
        const SizedBox(height: 8),
      ],
    );
  }
}
