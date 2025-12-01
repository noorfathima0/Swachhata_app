import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/imgbb_service.dart';

class AdminEventDetailPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const AdminEventDetailPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<AdminEventDetailPage> createState() => _AdminEventDetailPageState();
}

class _AdminEventDetailPageState extends State<AdminEventDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImgBBService _imgBB = ImgBBService();

  // ✅ Helper: Full image preview
  void _showFullImage(String imageUrl) {
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

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded, color: Colors.red.shade600),
            ),
            SizedBox(width: 12),
            Text(
              "Delete Event",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this event? This action cannot be undone.",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        actions: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('events').doc(widget.eventId).delete();
      if (mounted) {
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
                  Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Event deleted successfully",
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
        Navigator.pop(context);
      }
    }
  }

  Future<void> _editEvent(Map<String, dynamic> currentData) async {
    final titleController = TextEditingController(text: currentData['title']);
    final descController = TextEditingController(
      text: currentData['description'],
    );
    final locationController = TextEditingController(
      text: currentData['locationName'] ?? '',
    );
    DateTime selectedDate = (currentData['eventDate'] as Timestamp).toDate();
    List<String> currentImages =
        (currentData['mediaUrls'] as List?)?.cast<String>() ?? [];
    List<File> newImages = [];
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImages() async {
              final picker = ImagePicker();
              final picked = await picker.pickMultiImage();
              if (picked.isNotEmpty) {
                final newFiles = picked.map((e) => File(e.path)).toList();
                if (currentImages.length + newImages.length + newFiles.length >
                    5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Maximum 5 images allowed",
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
                } else {
                  setModalState(() {
                    newImages.addAll(newFiles);
                  });
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2C5F2D).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF2C5F2D),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Edit Event",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildTextField(
                      controller: titleController,
                      label: "Event Title",
                      icon: Icons.title_rounded,
                    ),
                    SizedBox(height: 16),

                    _buildTextField(
                      controller: descController,
                      label: "Description",
                      icon: Icons.description_rounded,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),

                    _buildTextField(
                      controller: locationController,
                      label: "Location",
                      icon: Icons.location_on_rounded,
                    ),
                    SizedBox(height: 20),

                    // 📅 Date & Time
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.orange.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Spacer(),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFF2C5F2D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.edit_calendar_rounded,
                              color: Color(0xFF2C5F2D),
                              size: 16,
                            ),
                            label: Text(
                              "Change",
                              style: TextStyle(
                                color: Color(0xFF2C5F2D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030),
                              );
                              if (pickedDate != null) {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    selectedDate,
                                  ),
                                );
                                if (pickedTime != null) {
                                  setModalState(() {
                                    selectedDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // 🖼️ Images
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: Colors.purple.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Images (${currentImages.length + newImages.length}/5)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Spacer(),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.add_photo_alternate_rounded,
                              color: Colors.purple.shade600,
                              size: 16,
                            ),
                            label: Text(
                              "Add More",
                              style: TextStyle(
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: pickImages,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    if (currentImages.isNotEmpty || newImages.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...currentImages.map(
                              (url) => GestureDetector(
                                onTap: () => _showFullImage(url),
                                child: Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.broken_image_rounded,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            ...newImages.map(
                              (file) => Container(
                                margin: EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    file,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),

                    // 💾 Save Button
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
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
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setModalState(() => isSaving = true);
                                      try {
                                        List<String> uploadedUrls = [];

                                        if (newImages.isNotEmpty) {
                                          for (var img in newImages) {
                                            final url = await _imgBB
                                                .uploadImage(img);
                                            uploadedUrls.add(url);
                                          }
                                        }

                                        final updatedData = {
                                          'title': titleController.text.trim(),
                                          'description': descController.text
                                              .trim(),
                                          'locationName': locationController
                                              .text
                                              .trim(),
                                          'eventDate': Timestamp.fromDate(
                                            selectedDate,
                                          ),
                                          'mediaUrls': [
                                            ...currentImages,
                                            ...uploadedUrls,
                                          ],
                                        };

                                        await _firestore
                                            .collection('events')
                                            .doc(widget.eventId)
                                            .update(updatedData);

                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF27AE60),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Event updated successfully",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "Failed to update: $e",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                        setModalState(() => isSaving = false);
                                      }
                                    },
                              child: isSaving
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Event Details",
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
              icon: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              onPressed: () async {
                final doc = await _firestore
                    .collection('events')
                    .doc(widget.eventId)
                    .get();
                if (doc.exists) _editEvent(doc.data() as Map<String, dynamic>);
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.delete_rounded, color: Colors.white, size: 20),
              onPressed: _deleteEvent,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading Event...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> mediaUrls =
              (data['mediaUrls'] as List?)?.cast<String>() ?? [];
          final String title = data['title'] ?? 'Untitled Event';
          final String description = data['description'] ?? '';
          final String location = data['locationName'] ?? 'No location';
          final Timestamp? eventDate = data['eventDate'];
          final formattedDate = eventDate != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(eventDate.toDate())
              : 'Unknown date';
          final List<dynamic> interestedUsers =
              (data['interestedUsers'] ?? []) as List<dynamic>;
          final isPast =
              eventDate != null && eventDate.toDate().isBefore(DateTime.now());

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼️ Media Carousel
                if (mediaUrls.isNotEmpty)
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
                                color: Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: Colors.purple.shade600,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Media Gallery (${mediaUrls.length})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 280,
                            enlargeCenterPage: true,
                            viewportFraction: 0.9,
                            enableInfiniteScroll: false,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 4),
                          ),
                          items: mediaUrls.map((url) {
                            return GestureDetector(
                              onTap: () => _showFullImage(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  url,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade100,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                if (mediaUrls.isNotEmpty) SizedBox(height: 20),

                // 📝 Event Details
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2C5F2D).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_rounded,
                              color: Color(0xFF2C5F2D),
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
                                          color: Colors.grey.shade800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPast
                                            ? Colors.grey.shade100
                                            : Color(
                                                0xFF27AE60,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isPast
                                              ? Colors.grey.shade300
                                              : Color(
                                                  0xFF27AE60,
                                                ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        isPast ? 'Past Event' : 'Upcoming',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isPast
                                              ? Colors.grey.shade600
                                              : Color(0xFF27AE60),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.orange.shade600,
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.red.shade600,
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Divider(height: 1, color: Colors.grey.shade200),
                      SizedBox(height: 20),
                      Column(
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
                                  Icons.description_rounded,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Description",
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
                            description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 👥 Interested Users
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
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_rounded,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Interested Users",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (interestedUsers.isEmpty)
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "No users have shown interest yet",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Share the event to get more participants",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${interestedUsers.length} user${interestedUsers.length > 1 ? 's' : ''} interested",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: interestedUsers.map((userId) {
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                                  builder: (context, userSnapshot) {
                                    if (userSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _buildUserChip(
                                        name: "Loading...",
                                        imageUrl: null,
                                      );
                                    }

                                    if (!userSnapshot.hasData ||
                                        !userSnapshot.data!.exists) {
                                      return _buildUserChip(
                                        name: "Unknown User",
                                        imageUrl: null,
                                      );
                                    }

                                    final user =
                                        userSnapshot.data!.data()
                                            as Map<String, dynamic>;

                                    return _buildUserChip(
                                      name: user['name'] ?? "User",
                                      imageUrl: user['profileImageUrl'],
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserChip({required String name, String? imageUrl}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(imageUrl),
            )
          else
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 14, color: Colors.green),
            ),
          SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(right: 12),
          child: Icon(icon, color: Color(0xFF2C5F2D)),
        ),
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
          borderSide: BorderSide(color: Color(0xFF2C5F2D), width: 2),
        ),
        contentPadding: EdgeInsets.all(16),
      ),
    );
  }
}
