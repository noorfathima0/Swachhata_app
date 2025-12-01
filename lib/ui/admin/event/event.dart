import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_detail.dart';
import 'event_form.dart';

class AdminEventPage extends StatefulWidget {
  const AdminEventPage({super.key});

  @override
  State<AdminEventPage> createState() => _AdminEventPageState();
}

class _AdminEventPageState extends State<AdminEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filter = 'Upcoming'; // Default filter

  Stream<QuerySnapshot> _getFilteredStream() {
    final now = DateTime.now();

    if (_filter == 'Upcoming') {
      return _firestore
          .collection('events')
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('eventDate', descending: false)
          .snapshots();
    } else if (_filter == 'Past') {
      return _firestore
          .collection('events')
          .where('eventDate', isLessThan: Timestamp.fromDate(now))
          .orderBy('eventDate', descending: true)
          .snapshots();
    } else {
      return _firestore
          .collection('events')
          .orderBy('eventDate', descending: false)
          .snapshots();
    }
  }

  // ✅ Helper: Show full image in dialog
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Event Management",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: Colors.white, size: 20),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventFormPage()),
                );
                setState(() {});
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),

          // 🔹 Filter Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: EdgeInsets.all(20),
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
                          Icons.filter_list_rounded,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Filter Events",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildFilterChip('Upcoming')),
                      SizedBox(width: 12),
                      Expanded(child: _buildFilterChip('Past')),
                      SizedBox(width: 12),
                      Expanded(child: _buildFilterChip('All')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // 🔹 Event List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading Events...",
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final events = snapshot.data!.docs;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final data = events[index].data() as Map<String, dynamic>;
                      final String title = data['title'] ?? 'Untitled Event';
                      final String description =
                          data['description'] ?? 'No description';
                      final Timestamp? ts = data['eventDate'];
                      final eventDate = ts?.toDate();
                      final formattedDate = eventDate != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(eventDate)
                          : 'Unknown date';
                      final List mediaUrls =
                          (data['mediaUrls'] ?? []) as List<dynamic>;
                      final hasMedia = mediaUrls.isNotEmpty;
                      final isPast =
                          eventDate != null &&
                          eventDate.isBefore(DateTime.now());

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(bottom: 16),
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminEventDetailPage(
                                    eventId: events[index].id,
                                    eventData: data,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🖼️ Event Thumbnail
                                  GestureDetector(
                                    onTap: hasMedia
                                        ? () => _showFullImage(mediaUrls.first)
                                        : null,
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: hasMedia
                                            ? Colors.transparent
                                            : Color(
                                                0xFF2C5F2D,
                                              ).withOpacity(0.1),
                                        image: hasMedia
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  mediaUrls.first,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: hasMedia
                                          ? null
                                          : Center(
                                              child: Icon(
                                                Icons.event_rounded,
                                                size: 32,
                                                color: Color(0xFF2C5F2D),
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: 16),

                                  // 📄 Event Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17,
                                                  color: Colors.grey.shade800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isPast
                                                    ? Colors.grey.shade100
                                                    : Color(
                                                        0xFF27AE60,
                                                      ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isPast
                                                      ? Colors.grey.shade300
                                                      : Color(
                                                          0xFF27AE60,
                                                        ).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                isPast ? 'Past' : 'Upcoming',
                                                style: TextStyle(
                                                  fontSize: 11,
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
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.access_time_rounded,
                                                color: Colors.orange.shade600,
                                                size: 14,
                                              ),
                                            ),
                                            SizedBox(width: 6),
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
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            if (hasMedia)
                                              Container(
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.shade50,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.photo_library_rounded,
                                                  color: Colors.purple.shade600,
                                                  size: 14,
                                                ),
                                              ),
                                            if (hasMedia) SizedBox(width: 6),
                                            if (hasMedia)
                                              Text(
                                                "${mediaUrls.length} photo${mediaUrls.length > 1 ? 's' : ''}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.grey.shade600,
                                                size: 14,
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
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2C5F2D) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2C5F2D) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2C5F2D).withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 70,
                color: Colors.grey.shade300,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "No ${_filter.toLowerCase()} events",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _filter == 'Upcoming'
                  ? "Create new events to engage with the community"
                  : _filter == 'Past'
                  ? "Past events will appear here for review"
                  : "Start by creating your first event",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF2C5F2D), Color(0xFF1E3A1E)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2C5F2D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                label: Text(
                  "Create Event",
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventFormPage()),
                  );
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
