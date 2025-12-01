import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayEventsPage extends StatefulWidget {
  final DateTime selectedDate;

  const DayEventsPage({super.key, required this.selectedDate});

  @override
  State<DayEventsPage> createState() => _DayEventsPageState();
}

class _DayEventsPageState extends State<DayEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> _getEventsForDay() {
    final startOfDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('events')
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('eventDate', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  Future<void> _toggleInterest(
    String eventId,
    List<dynamic> interestedUsers,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please login to show interest"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final userId = user.uid;
    final eventRef = _firestore.collection('events').doc(eventId);

    if (interestedUsers.contains(userId)) {
      await eventRef.update({
        'interestedUsers': FieldValue.arrayRemove([userId]),
      });
    } else {
      await eventRef.update({
        'interestedUsers': FieldValue.arrayUnion([userId]),
      });
    }

    setState(() {});
  }

  bool _isUpcoming(DateTime eventDate) => eventDate.isAfter(DateTime.now());

  void _showFullImageDialog(String imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: 80,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Failed to load image",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Purple theme colors matching the Events dashboard box
  final Color primaryColor = const Color(0xFF673AB7);
  final Color primaryDark = const Color(0xFF512DA8);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
  );

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final formattedDate = DateFormat('dd MMM yyyy').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Events on $formattedDate",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getEventsForDay(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Loading events...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Error loading events",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data!.docs;
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: primaryColor,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No events for this date",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check other dates for events",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final user = _auth.currentUser;
          final userId = user?.uid;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data() as Map<String, dynamic>;
              final eventId = events[index].id;

              final String title = data['title'] ?? 'Untitled Event';
              final String description = data['description'] ?? '';
              final String location = data['locationName'] ?? 'No location';
              final Timestamp? ts = data['eventDate'];
              final eventDate = ts?.toDate() ?? DateTime.now();
              final List<dynamic> mediaUrls =
                  (data['mediaUrls'] ?? []) as List<dynamic>;
              final List<dynamic> interestedUsers =
                  (data['interestedUsers'] ?? []) as List<dynamic>;

              final bool isInterested =
                  userId != null && interestedUsers.contains(userId);
              final bool isUpcoming = _isUpcoming(eventDate);
              final statusColor = isUpcoming
                  ? Colors.green.shade600
                  : Colors.grey.shade600;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Image
                    if (mediaUrls.isNotEmpty)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullImageDialog(mediaUrls.first),
                            child: Container(
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: Image.network(
                                  mediaUrls.first,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 220,
                                    color: primaryColor.withOpacity(0.1),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          size: 60,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Image not available",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.05),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.zoom_in_rounded,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Tap to zoom",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    // Event Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUpcoming
                                          ? Icons.upcoming_rounded
                                          : Icons.history_rounded,
                                      color: statusColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isUpcoming ? "Upcoming" : "Past Event",
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy • hh:mm a',
                                ).format(eventDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Description
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Interested Section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFF3D3D3D)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isInterested
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isInterested
                                            ? Colors.red
                                            : isDarkMode
                                            ? Colors.white60
                                            : Colors.grey,
                                        size: 28,
                                      ),
                                      onPressed: () async {
                                        await _toggleInterest(
                                          eventId,
                                          interestedUsers,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${interestedUsers.length}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Text(
                                      "interested",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    "Join Event",
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
