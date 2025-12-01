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
                  "Activity approved and published!",
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

  Future<void> _rejectActivity() async {
    setState(() => _isProcessing = true);

    await _firestore.collection('activities').doc(widget.activityId).update({
      'status': 'Rejected',
    });

    if (mounted) {
      setState(() => _isProcessing = false);
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
                Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "Activity rejected",
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

  /// Show full-screen image dialog
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Color(0xFF27AE60);
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Color(0xFFE67E22);
    }
  }

  IconData _getActivityIcon(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toLowerCase();
    final description = (data['description'] ?? '').toLowerCase();

    if (title.contains('clean') || description.contains('clean')) {
      return Icons.cleaning_services_rounded;
    } else if (title.contains('plant') || description.contains('plant')) {
      return Icons.eco_rounded;
    } else if (title.contains('recycl') || description.contains('recycl')) {
      return Icons.recycling_rounded;
    } else if (title.contains('awareness') || description.contains('awareness')) {
      return Icons.campaign_rounded;
    } else if (title.contains('meet') || description.contains('meet')) {
      return Icons.groups_rounded;
    } else {
      return Icons.volunteer_activism_rounded;
    }
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Activity Review",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧾 Header Card
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActivityIcon(data),
                      color: _statusColor(status),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: Colors.grey.shade800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _statusColor(status),
                                    _statusColor(status).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.blue.shade600,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Submitted by $userName",
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
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                color: Colors.green.shade600,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 🖼 Media Carousel Section
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
                        enableInfiniteScroll: false,
                        viewportFraction: 0.9,
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
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            if (mediaUrls.isNotEmpty) SizedBox(height: 20),

            // 📝 Description Section
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
                          Icons.description_rounded,
                          color: Colors.orange.shade600,
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
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.red.shade600,
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
                  Row(
                    children: [
                      Icon(Icons.place_rounded, color: Colors.grey.shade600, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locationName,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
                            markerId: MarkerId("activity_location"),
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
                ],
              ),
            ),

            SizedBox(height: 20),

            // ✅ Approve / Reject Controls
            if (status == 'Pending')
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
                            Icons.verified_rounded,
                            color: Colors.green.shade600,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Review Actions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF27AE60), Color(0xFF229954)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF27AE60).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: _isProcessing
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Icon(Icons.check_rounded, color: Colors.white, size: 20),
                              label: Text(
                                _isProcessing ? "Processing..." : "Approve & Publish",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isProcessing ? null : _approveActivity,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.red.shade600, Colors.red.shade800],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                              label: Text(
                                "Reject",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isProcessing ? null : _rejectActivity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}