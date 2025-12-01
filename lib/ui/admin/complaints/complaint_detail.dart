import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class ComplaintDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot data;

  const ComplaintDetailPage({super.key, required this.data});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  late Map<String, dynamic> complaint;
  final TextEditingController _noteController = TextEditingController();
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    complaint = widget.data.data() as Map<String, dynamic>;
    _selectedStatus = complaint['status'];
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaint['complaintId'])
          .update({'status': newStatus});

      setState(() {
        _selectedStatus = newStatus;
        complaint['status'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF27AE60),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Status updated to '$newStatus'",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Failed to update: $e",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaint['complaintId'])
          .update({'adminNote': note});

      setState(() => complaint['adminNote'] = note);
      _noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2C5F2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.note_add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Note added successfully",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Failed to add note: $e",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<pw.MemoryImage?> _loadNetworkImage(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint("Error loading image: $e");
      return null;
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final createdAt = complaint['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : 'Unknown date';

    final pw.MemoryImage? image = complaint['imageUrl'] != null
        ? await _loadNetworkImage(complaint['imageUrl'])
        : null;

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Complaint Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Complaint ID: ${complaint['complaintId']}"),
              pw.Text("User ID: ${complaint['userId']}"),
              pw.Text("Type: ${complaint['type']}"),
              pw.Text("Status: ${complaint['status']}"),
              pw.Text("Submitted on: $formattedDate"),
              pw.SizedBox(height: 10),
              pw.Text("Description: ${complaint['description']}"),
              pw.SizedBox(height: 10),
              pw.Text(
                "Location: (${complaint['latitude']}, ${complaint['longitude']})",
              ),
              if (complaint['address'] != null)
                pw.Text("Address: ${complaint['address']}"),
              if (complaint['adminNote'] != null &&
                  complaint['adminNote'].toString().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text("Admin Note: ${complaint['adminNote']}"),
                ),
              pw.SizedBox(height: 20),
              if (image != null)
                pw.Image(image, height: 250, fit: pw.BoxFit.cover)
              else
                pw.Text("Image not available"),
            ],
          ),
        ),
      ),
    );
    return pdf;
  }

  Future<void> _exportPDF() async {
    final pdf = await _generatePDF();
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _downloadPDF() async {
    try {
      final pdf = await _generatePDF();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/complaint_${complaint['complaintId']}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2C5F2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.download_done_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "PDF saved to: ${file.path}",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Error saving PDF: $e",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// ✅ Show enlarged image in a dialog
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 100,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'Resolved' => Color(0xFF27AE60),
      'In-Progress' => Color(0xFFE67E22),
      'Rejected' => Colors.red.shade600,
      _ => Colors.blueGrey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final latitude = complaint['latitude'] ?? 0.0;
    final longitude = complaint['longitude'] ?? 0.0;
    final imageUrl = complaint['imageUrl'] ?? '';
    final address = complaint['address'] ?? 'No address available';

    final createdAt = complaint['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : 'Unknown date';

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Complaint Details",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 20,
              ),
              tooltip: "Export as PDF",
              onPressed: _exportPDF,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.download_rounded, color: Colors.white, size: 20),
              tooltip: "Download PDF",
              onPressed: _downloadPDF,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Clickable Complaint Image Card
                GestureDetector(
                  onTap: () {
                    if (imageUrl.isNotEmpty) {
                      _showImageDialog(imageUrl);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 240,
                          color: Colors.grey.shade100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Image not available",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // 🏷 Complaint Info Card
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              complaint['type'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getStatusColor(
                                    _selectedStatus ?? 'Submitted',
                                  ),
                                  _getStatusColor(
                                    _selectedStatus ?? 'Submitted',
                                  ).withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedStatus ?? 'Pending',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildInfoRow("Complaint ID", complaint['complaintId']),
                      _buildInfoRow("Submitted", formattedDate),
                      SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.shade200),
                      SizedBox(height: 16),
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        complaint['description'] ?? "No description provided.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 📍 Location Section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Location",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(latitude, longitude),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId("complaint_location"),
                                position: LatLng(latitude, longitude),
                                infoWindow: InfoWindow(
                                  title: complaint['type'] ?? "Complaint",
                                ),
                              ),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 🔄 Status Change + Note Section
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.update_rounded,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Update Complaint Status",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFF2C5F2D),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Submitted",
                            child: Text("Submitted"),
                          ),
                          DropdownMenuItem(
                            value: "In-Progress",
                            child: Text("In Progress"),
                          ),
                          DropdownMenuItem(
                            value: "Resolved",
                            child: Text("Resolved"),
                          ),
                          DropdownMenuItem(
                            value: "Rejected",
                            child: Text("Rejected"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null && value != _selectedStatus) {
                            _updateStatus(value);
                          }
                        },
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.note_add_rounded,
                              color: Colors.purple.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Admin Note",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Write admin note...",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFF2C5F2D),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF2C5F2D).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              "Save Note",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _addNote,
                          ),
                        ),
                      ),
                      if (complaint['adminNote'] != null &&
                          complaint['adminNote'].toString().isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF2C5F2D).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF2C5F2D).withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_rounded,
                                    color: Color(0xFF2C5F2D),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Saved Note",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C5F2D),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                complaint['adminNote'],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Updating Status...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
