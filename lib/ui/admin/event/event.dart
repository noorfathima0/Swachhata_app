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
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white70,
                  size: 80,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tealColor = Colors.teal.shade600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Admin Events",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: tealColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventFormPage()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  "Filter:",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filter,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Upcoming',
                      child: Text('Upcoming Events'),
                    ),
                    DropdownMenuItem(value: 'Past', child: Text('Past Events')),
                    DropdownMenuItem(value: 'All', child: Text('All Events')),
                  ],
                  onChanged: (value) => setState(() => _filter = value!),
                ),
              ],
            ),
          ),

          // 🔹 Event List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No $_filter events found.",
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                final events = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
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

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
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
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🖼️ Event Thumbnail (Clickable)
                              if (mediaUrls.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _showFullImage(mediaUrls.first),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Hero(
                                      tag: mediaUrls.first,
                                      child: Image.network(
                                        mediaUrls.first,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.event,
                                    size: 40,
                                    color: Colors.teal,
                                  ),
                                ),

                              const SizedBox(width: 14),

                              // 📄 Event Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: tealColor,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
