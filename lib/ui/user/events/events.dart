import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'day_events.dart';

class UserEventsPage extends StatefulWidget {
  const UserEventsPage({super.key});

  @override
  State<UserEventsPage> createState() => _UserEventsPageState();
}

class _UserEventsPageState extends State<UserEventsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _eventsByDate = {};
  List<Map<String, dynamic>> _allEvents = [];

  // Color scheme
  final Color _primaryColor = Colors.teal;
  final Color _primaryDark = Color(0xFF00695C);
  final Color _primaryLight = Color(0xFF4DB6AC);
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final snapshot = await _firestore.collection('events').get();
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    final List<Map<String, dynamic>> all = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['eventDate'] == null) continue;
      final eventDate = (data['eventDate'] as Timestamp).toDate();
      final dateKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add({...data, 'id': doc.id});

      all.add({...data, 'id': doc.id});
    }

    // Sort events by date (upcoming first)
    all.sort((a, b) {
      final dateA = (a['eventDate'] as Timestamp).toDate();
      final dateB = (b['eventDate'] as Timestamp).toDate();
      return dateA.compareTo(dateB);
    });

    setState(() {
      _eventsByDate = grouped;
      _allEvents = all;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _eventsByDate[dateKey] ?? [];
  }

  bool _isUpcoming(DateTime eventDate) {
    return eventDate.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    // Determine which list to show
    final List<Map<String, dynamic>> displayedEvents = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : _allEvents;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Community Events",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- Calendar View ---
          Card(
            elevation: 3,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: _getEventsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    if (_selectedDay != null &&
                        isSameDay(_selectedDay, selectedDay)) {
                      // If same date clicked again → deselect (show all)
                      _selectedDay = null;
                    } else {
                      _selectedDay = selectedDay;
                    }
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryDark,
                    fontSize: 16,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: _primaryColor,
                    size: 24,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: _primaryLight,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.grey[800]),
                  weekendTextStyle: TextStyle(color: Colors.grey[800]),
                  holidayTextStyle: TextStyle(color: Colors.grey[800]),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: _primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: _primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDay == null
                    ? "All Events"
                    : "Events on ${DateFormat('dd MMM yyyy').format(_selectedDay!)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryDark,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // --- Events List ---
          Expanded(
            child: displayedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: _primaryLight),
                        const SizedBox(height: 16),
                        Text(
                          "No events available",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: _primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDay == null
                              ? "Check back later for new events"
                              : "No events scheduled for this date",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: displayedEvents.length,
                    itemBuilder: (context, index) {
                      final event = displayedEvents[index];
                      final title = event['title'] ?? 'Untitled Event';
                      final description =
                          event['description'] ?? 'No description available';
                      final eventDate = (event['eventDate'] as Timestamp)
                          .toDate();
                      final formattedDate = DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(eventDate);

                      final isUpcoming = _isUpcoming(eventDate);
                      final statusColor = isUpcoming
                          ? Colors.green
                          : Colors.grey.shade700;
                      final statusText = isUpcoming ? "Upcoming" : "Past Event";

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: _cardColor,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _primaryLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _primaryLight.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.event,
                              color: _primaryColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _primaryDark,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUpcoming
                                          ? Icons.upcoming
                                          : Icons.history,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: _primaryLight,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DayEventsPage(selectedDate: eventDate),
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
}
