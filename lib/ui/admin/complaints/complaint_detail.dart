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
        SnackBar(content: Text("✅ Status updated to '$newStatus'")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to update: $e")));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("📝 Note added")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed: $e")));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Saved to: ${file.path}")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error saving PDF: $e")));
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
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Complaint Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export as PDF",
            onPressed: _exportPDF,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: "Download PDF",
            onPressed: _downloadPDF,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 240, color: Colors.grey[300]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🏷 Complaint Info Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              complaint['type'] ?? 'Unknown',
                              style: theme.textTheme.titleLarge!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Chip(
                              label: Text(
                                _selectedStatus ?? 'Pending',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: switch (_selectedStatus) {
                                'Resolved' => Colors.green,
                                'In-Progress' => Colors.orange,
                                'Rejected' => Colors.redAccent,
                                _ => Colors.blueGrey,
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Complaint ID: ${complaint['complaintId']}",
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "Submitted: $formattedDate",
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const Divider(height: 24),
                        Text(
                          complaint['description'] ??
                              "No description provided.",
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 📍 Location Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Location",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          address,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 250,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(latitude, longitude),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId(
                                    "complaint_location",
                                  ),
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
                ),

                const SizedBox(height: 20),

                // 🔄 Status Change + Note Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Update Complaint Status",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(height: 20),
                        const Text(
                          "Admin Note",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Write admin note...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.note_add_rounded),
                            label: const Text("Save Note"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _addNote,
                          ),
                        ),
                        if (complaint['adminNote'] != null &&
                            complaint['adminNote'].toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "🗒️ Saved Note:\n${complaint['adminNote']}",
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
