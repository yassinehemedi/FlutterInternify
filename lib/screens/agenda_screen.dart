import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/EventService.dart';
import 'add_event_screen.dart';
import 'event_screen.dart'; // Import the new screen

class AgendaScreen extends StatefulWidget {
  final int userId;
  const AgendaScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AgendaScreenState createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();

  // Future to hold the list of all events, fetched only once.
  late Future<List<Event>> _allEventsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch all events when the screen is first initialized.
    _allEventsFuture = _eventService.getEvents(widget.userId);
    _searchController.addListener(() {
      // Rebuild the widget to apply the filter instantly.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get an icon based on event type
  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'task':
        return Icons.task_alt;
      case 'meeting':
        return Icons.people;
      case 'report':
        return Icons.article;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Agenda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
            stops: const [0.0, 0.4],
          ),
        ),
        child: _currentIndex == 0 ? _buildCalendarView() : _buildListView(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.blue[50],
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEventScreen(userId: widget.userId),
            ),
          );
          if (result == true) {
            // Refresh the list if an event was added
            setState(() {
              _allEventsFuture = _eventService.getEvents(widget.userId);
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: DatePicker(
            DateTime.now(),
            height: 85,
            width: 72,
            initialSelectedDate: _selectedDate,
            selectionColor: Colors.blue[700]!,
            selectedTextColor: Colors.white,
            dateTextStyle: TextStyle(
              color: Colors.blue[800],
              fontSize: 20,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
            dayTextStyle: TextStyle(
              color: Colors.blue[800],
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
            monthTextStyle: TextStyle(
              color: Colors.blue[800],
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
            deactivatedColor: Colors.grey,
            locale: "fr_FR",
            daysCount: 8,
            onDateChange: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Event>>(
            future: _eventService.getEventsByDate(widget.userId, DateFormat('yyyy-MM-dd').format(_selectedDate)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red[300])));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_outlined, size: 80, color: Colors.blue[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No events for this day',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final events = snapshot.data!;
                events.sort((a, b) => a.deadlineTime.compareTo(b.deadlineTime));
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    Event event = events[index];
                    return _buildEventCard(event, true);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by title, description...',
              prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Event>>(
            future: _allEventsFuture, // Use the single future here
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red[300])));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_outlined, size: 80, color: Colors.blue[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Filter and sort the already-fetched list in memory
                final allEvents = snapshot.data!;
                final filteredEvents = _eventService.filterEvents(allEvents, _searchController.text);
                filteredEvents.sort((a, b) {
                  final aDeadline = DateFormat('yyyy-MM-dd HH:mm').parse('${a.deadlineDate} ${a.deadlineTime}');
                  final bDeadline = DateFormat('yyyy-MM-dd HH:mm').parse('${b.deadlineDate} ${b.deadlineTime}');
                  return aDeadline.compareTo(bDeadline);
                });

                if (_searchController.text.isNotEmpty && filteredEvents.isEmpty) {
                  return Center(
                    child: Text('No results found', style: TextStyle(color: Colors.blue[900], fontSize: 18)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    Event event = filteredEvents[index];
                    return _buildEventCard(event, false);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event, bool isCalendarView) {
    final statusColor = _getStatusColor(event.status);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventScreen(event: event),
            ),
          );
          if (result == true) {
            // Refresh the list if an event was updated or deleted
            setState(() {
              _allEventsFuture = _eventService.getEvents(widget.userId);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getTypeIcon(event.type), color: Colors.blue[600], size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (event.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCalendarView ? Icons.access_time : Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCalendarView ? 'Deadline: ${event.deadlineTime}' : 'Deadline: ${event.deadlineDate}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  if (!isCalendarView) // Only show time on the right for List view
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          event.deadlineTime,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
