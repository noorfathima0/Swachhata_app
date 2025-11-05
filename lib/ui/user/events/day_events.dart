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
    if (user == null) return;

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

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(widget.selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Events on $formattedDate",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getEventsForDay(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          final events = snapshot.data!.docs;
          if (events.isEmpty) {
            return const Center(
              child: Text(
                "No events for this date.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final user = _auth.currentUser;
          final userId = user?.uid;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: Colors.teal.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Event Image (clickable) ---
                      if (mediaUrls.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.black.withOpacity(0.9),
                                insetPadding: const EdgeInsets.all(10),
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          mediaUrls.first,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.broken_image,
                                                color: Colors.white,
                                                size: 60,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              mediaUrls.first,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 80),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // --- Title & Date ---
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy • hh:mm a').format(eventDate),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // --- Location ---
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
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // --- Description ---
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- Interested Section ---
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isInterested
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInterested
                                  ? Colors.redAccent
                                  : Colors.grey,
                              size: 28,
                            ),
                            onPressed: () async {
                              await _toggleInterest(eventId, interestedUsers);
                            },
                          ),
                          Text(
                            "${interestedUsers.length} interested",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isUpcoming
                                  ? Colors.teal.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.15),
                              border: Border.all(
                                color: isUpcoming ? Colors.teal : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUpcoming ? "Upcoming" : "Past Event",
                              style: TextStyle(
                                color: isUpcoming
                                    ? Colors.teal[700]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
      ),
    );
  }
}
