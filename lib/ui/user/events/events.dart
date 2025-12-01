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

  String _filterType = "all"; // all, upcoming, past

  final Color primaryColor = const Color(0xFF673AB7);
  final Color primaryDark = const Color(0xFF512DA8);
  final LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
  );

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
    final key = DateTime(day.year, day.month, day.day);
    return _eventsByDate[key] ?? [];
  }

  bool _isUpcoming(DateTime date) => date.isAfter(DateTime.now());
  bool _isPast(DateTime date) => date.isBefore(DateTime.now());

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> events) {
    if (_filterType == "upcoming") {
      return events
          .where((e) => _isUpcoming((e['eventDate'] as Timestamp).toDate()))
          .toList();
    } else if (_filterType == "past") {
      return events
          .where((e) => _isPast((e['eventDate'] as Timestamp).toDate()))
          .toList();
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = dark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = dark ? const Color(0xFF1E1E1E) : Colors.white;

    List<Map<String, dynamic>> events = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : _allEvents;

    events = _applyFilter(events);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Community Events",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: const Icon(
                      Icons.event_available,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Community Events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),

            // CALENDAR (NOW SCROLLS!)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2022, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: _getEventsForDay,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = isSameDay(_selectedDay, selected)
                        ? null
                        : selected;
                    _focusedDay = focused;
                  });
                },
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : primaryDark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FILTER BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: primaryColor,
                color: primaryColor,
                isSelected: [
                  _filterType == "all",
                  _filterType == "upcoming",
                  _filterType == "past",
                ],
                onPressed: (i) {
                  setState(() {
                    _filterType = ["all", "upcoming", "past"][i];
                  });
                },
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text("All")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Upcoming")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Past")),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedDay == null
                      ? "${_filterType[0].toUpperCase()}${_filterType.substring(1)} Events"
                      : "Events on ${DateFormat('dd MMM yyyy').format(_selectedDay!)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : primaryDark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // EVENTS LIST (scrolls together)
            Column(
              children: events.map((event) {
                final title = event["title"] ?? "Untitled Event";
                final desc = event["description"] ?? "";
                final date = (event["eventDate"] as Timestamp).toDate();
                final formatted = DateFormat(
                  "dd MMM yyyy, hh:mm a",
                ).format(date);

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),

                      // ⭐ OPEN DAY_EVENTS PAGE HERE
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayEventsPage(selectedDate: date),
                          ),
                        );
                      },

                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 40, color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: dark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatted,
                                    style: TextStyle(
                                      color: dark
                                          ? Colors.white70
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: dark
                                          ? Colors.white60
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
