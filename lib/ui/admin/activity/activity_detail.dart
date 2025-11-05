import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class AdminActivityDetailPage extends StatefulWidget {
  final Map<String, dynamic> activityData;
  final String activityId;

  const AdminActivityDetailPage({
    super.key,
    required this.activityData,
    required this.activityId,
  });

  @override
  State<AdminActivityDetailPage> createState() =>
      _AdminActivityDetailPageState();
}

class _AdminActivityDetailPageState extends State<AdminActivityDetailPage> {
  bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _approveActivity() async {
    setState(() => _isProcessing = true);

    final data = widget.activityData;

    await _firestore.collection('posts').add({
      'content': "${data['title']}\n\n${data['description']}",
      'mediaUrls': data['mediaUrls'] ?? [],
      'adminName': data['Name'] ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
      'commentCount': 0,
      'location': {
        'name': data['locationName'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
      },
    });

    await _firestore.collection('activities').doc(widget.activityId).update({
      'status': 'Approved',
    });

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Activity approved and published!")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _rejectActivity() async {
    setState(() => _isProcessing = true);

    await _firestore.collection('activities').doc(widget.activityId).update({
      'status': 'Rejected',
    });

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Activity rejected.")));
      Navigator.pop(context);
    }
  }

  /// Show full-screen image dialog
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 100),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.activityData;
    final List<String> mediaUrls =
        (data['mediaUrls'] as List?)?.cast<String>() ?? [];
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final userName = data['userName'] ?? 'Unknown User';
    final status = data['status'] ?? 'Pending';
    final locationName = data['address'] ?? 'Unknown Location';
    final latitude = data['latitude'] ?? 0.0;
    final longitude = data['longitude'] ?? 0.0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : 'Unknown Date';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Activity Review"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧾 Title and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        status,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _statusColor(status),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Submitted by $userName • $formattedDate",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // 🖼 Media Carousel (Clickable)
                if (mediaUrls.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 280,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                      viewportFraction: 1,
                    ),
                    items: mediaUrls.map((url) {
                      return GestureDetector(
                        onTap: () => _showFullImage(url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 80),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // 📝 Description
                const Text(
                  "Description",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),

                const SizedBox(height: 20),

                // 📍 Location Details
                const Text(
                  "Location",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🗺 Map Section
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
                          markerId: const MarkerId("activity_location"),
                          position: LatLng(latitude, longitude),
                          infoWindow: InfoWindow(title: locationName),
                        ),
                      },
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ Approve / Reject Controls
                if (status == 'Pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text(
                            "Approve & Publish",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _approveActivity(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text(
                            "Reject",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => _rejectActivity(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
