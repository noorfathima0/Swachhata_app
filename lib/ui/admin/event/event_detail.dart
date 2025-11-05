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
        backgroundColor: Colors.black.withOpacity(0.9),
        insetPadding: const EdgeInsets.all(8),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image,
                size: 80,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('events').doc(widget.eventId).delete();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _editEvent(Map<String, dynamic> currentData) async {
    final titleController = TextEditingController(text: currentData['title']);
    final descController = TextEditingController(
      text: currentData['description'],
    );
    final locationController = TextEditingController(
      text: currentData['locationName'],
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
                setModalState(() {
                  newImages.addAll(picked.map((e) => File(e.path)).toList());
                });
              }
            }

            return AlertDialog(
              title: const Text("Edit Event"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(selectedDate),
                        ),
                        const Spacer(),
                        TextButton(
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
                          child: const Text("Change"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Images:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...currentImages.map(
                            (url) => GestureDetector(
                              onTap: () => _showFullImage(url),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ...newImages.map(
                            (file) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  file,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: pickImages,
                            icon: const Icon(
                              Icons.add_a_photo,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          try {
                            List<String> uploadedUrls = [];

                            if (newImages.isNotEmpty) {
                              for (var img in newImages) {
                                final url = await _imgBB.uploadImage(img);
                                uploadedUrls.add(url);
                              }
                            }

                            final updatedData = {
                              'title': titleController.text.trim(),
                              'description': descController.text.trim(),
                              'locationName': locationController.text.trim(),
                              'eventDate': Timestamp.fromDate(selectedDate),
                              'mediaUrls': [...currentImages, ...uploadedUrls],
                            };

                            await _firestore
                                .collection('events')
                                .doc(widget.eventId)
                                .update(updatedData);

                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to update: $e")),
                            );
                          } finally {
                            setModalState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tealColor = Colors.teal.shade600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Event Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: tealColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final doc = await _firestore
                  .collection('events')
                  .doc(widget.eventId)
                  .get();
              if (doc.exists) _editEvent(doc.data() as Map<String, dynamic>);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mediaUrls.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 250,
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: false,
                    ),
                    items: mediaUrls.map((url) {
                      return GestureDetector(
                        onTap: () => _showFullImage(url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: url,
                            child: Image.network(
                              url,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 100),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tealColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.teal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 30),

                Text(
                  description,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 25),
                const Text(
                  "Interested Users",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (interestedUsers.isEmpty)
                  const Text(
                    "No users have shown interest yet.",
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${interestedUsers.length} users interested",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: interestedUsers.map((userName) {
                          return Chip(
                            label: Text(userName.toString()),
                            backgroundColor: Colors.teal.shade50,
                            side: BorderSide(color: tealColor.withOpacity(0.4)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
