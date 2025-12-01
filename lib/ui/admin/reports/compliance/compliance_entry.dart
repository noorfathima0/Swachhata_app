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

  DateTime? _toDate(dynamic t) => t is Timestamp ? t.toDate() : null;

  // ---------------------------------------------------------------------------
  // DATE PICKER
  // ---------------------------------------------------------------------------
  Future<void> _pickDate(Function(DateTime) onPicked) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDate: DateTime.now(),
    );
    if (d != null) onPicked(d);
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // FILE UPLOADER
  // ---------------------------------------------------------------------------
  Future<String?> uploadFile() async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    if (pick == null) return null;

    final file = File(pick.files.first.path!);
    return await imgbb.uploadImage(file);
  }

  // ---------------------------------------------------------------------------
  // SAVE OR UPDATE
  // ---------------------------------------------------------------------------
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
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: Text(
          editing ? "Edit Compliance" : "Add Compliance",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal.shade800,
        elevation: 0,
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionCard(
            icon: Icons.local_shipping,
            title: "Vehicle Details",
            children: [_inputField("Vehicle Number", vehicleCtrl)],
          ),

          const SizedBox(height: 20),

          _sectionCard(
            icon: Icons.date_range,
            title: "Insurance & Renewals",
            children: [
              _datePickerTile(
                "Insurance Start Date",
                insuranceStart,
                (d) => insuranceStart = d,
              ),
              _datePickerTile(
                "Insurance End Date",
                insuranceEnd,
                (d) => insuranceEnd = d,
              ),
              _datePickerTile(
                "General Renewal Due Date",
                renewalDue,
                (d) => renewalDue = d,
              ),
            ],
          ),

          const SizedBox(height: 20),

          _sectionCard(
            icon: Icons.security,
            title: "Compliance Renewals",
            children: [
              _datePickerTile(
                "Pollution Licence Renewal",
                pollutionRenew,
                (d) => pollutionRenew = d,
              ),
              _datePickerTile(
                "Labor Insurance Renewal",
                laborInsurance,
                (d) => laborInsurance = d,
              ),
              _datePickerTile("Vehicle FC Due Date", fcDue, (d) => fcDue = d),
            ],
          ),

          const SizedBox(height: 20),

          _sectionCard(
            icon: Icons.file_present,
            title: "Upload Compliance Documents",
            children: [
              _uploadTile(
                "Pollution Document",
                pollutionUrl,
                (url) => pollutionUrl = url,
              ),
              _uploadTile(
                "Labor Insurance Document",
                laborUrl,
                (url) => laborUrl = url,
              ),
              _uploadTile("FC Certificate", fcUrl, (url) => fcUrl = url),
            ],
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: saveEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              editing ? "Update Compliance" : "Save Compliance",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION CARD
  // ---------------------------------------------------------------------------
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
                radius: 22,
                backgroundColor: Colors.teal.withOpacity(.15),
                child: Icon(icon, color: Colors.teal.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
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

  // ---------------------------------------------------------------------------
  // INPUT FIELD
  // ---------------------------------------------------------------------------
  Widget _inputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          labelText: label,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATE PICKER TILE
  // ---------------------------------------------------------------------------
  Widget _datePickerTile(
    String label,
    DateTime? value,
    Function(DateTime) onPicked,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _pickDate(onPicked),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.teal.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : "$label: ${value.toString().split(" ").first}",
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILE UPLOAD TILE
  // ---------------------------------------------------------------------------
  Widget _uploadTile(String label, String? url, Function(String) onUploaded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),

          const SizedBox(height: 10),

          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text("Choose File"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final uploaded = await uploadFile();
              if (uploaded != null) {
                onUploaded(uploaded);
                setState(() {});
              }
            },
          ),

          if (url != null) ...[
            const SizedBox(height: 6),
            Text(
              "Uploaded ✔",
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
