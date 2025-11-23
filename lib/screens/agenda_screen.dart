import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../services/home_service.dart';

import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
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
  String _selectedStatusFilter = 'All';
  Timer? _timer;

  // Future to hold the list of all events, fetched only once.
  late Future<List<Event>> _allEventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(() {
      // Rebuild the widget to apply the filter instantly.
      setState(() {});
    });
    // Set up a timer to check for expired events every 5 seconds.
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
      if (!mounted) return; // Add a mounted check
      final List<Event> newlyExpiredEvents = await _eventService.updateExpiredEvents(widget.userId);
      if (newlyExpiredEvents.isNotEmpty && mounted) {
        // If events were updated, show an alert and refresh the list.
        _showExpiredEventsDialog(newlyExpiredEvents);
        _loadEvents();
      }
    });
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _allEventsFuture = _eventService.getEvents(widget.userId);
      });
    }
  }
  
  void _showExpiredEventsDialog(List<Event> expiredEvents) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Events Expired', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following events have passed their deadlines:',
                style: TextStyle(fontSize: 16, color: Colors.grey[800])
              ),
              const SizedBox(height: 16),
              ...expiredEvents.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.label_important, color: Colors.red[300], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDailyStatistics(BuildContext context, List<Event> dailyEvents) {
    final stats = _eventService.calculateDailyStatistics(dailyEvents);
    final typePercentages = stats['typePercentages'] as Map<String, double>;
    final typeCounts = stats['typeCounts'] as Map<String, int>;
    final inProgressPercentage = stats['inProgressPercentage'] as double;
    final donePercentage = stats['donePercentage'] as double;
    final motivationalMessage = stats['motivationalMessage'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[50]!],
                  stops: const [0.0, 0.4],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Text(
                      'Daily Performance',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPieChart(typePercentages, typeCounts),
                  const SizedBox(height: 20),
                  _buildStatCard('In Progress', inProgressPercentage, Icons.directions_run, Colors.orange),
                  const SizedBox(height: 12),
                  _buildStatCard('Done', donePercentage, Icons.check_circle, Colors.green),
                  const SizedBox(height: 20),
                  _buildMotivationalCard(motivationalMessage),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPieChart(Map<String, double> data, Map<String, int> counts) {
    List<Widget> legend = [];
    List<Widget> chartBars = [];
    final colors = {'task': Colors.purple, 'meeting': Colors.teal, 'report': Colors.amber};

    data.forEach((key, value) {
      if (value > 0) {
        final count = counts[key]!;
        legend.add(_buildLegendItem(colors[key]!, key));
        chartBars.add(Flexible(
          flex: value.toInt(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: colors[key]!),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 1.5, color: Colors.black54)],
                ),
              ),
            ],
          ),
        ));
      }
    });

    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Event Types Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(height: 20, child: Row(children: chartBars)),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 20, runSpacing: 8, children: legend),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(text[0].toUpperCase() + text.substring(1), style: TextStyle(color: Colors.blue[900])),
      ],
    );
  }

  Widget _buildStatCard(String title, double percentage, IconData icon, Color color) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalCard(String message) {
    Color cardColor;
    IconData icon;
    switch (message) {
      case 'Very Good!':
        cardColor = Colors.green[700]!;
        icon = Icons.star;
        break;
      case 'A little bit left!':
        cardColor = Colors.orange[700]!;
        icon = Icons.trending_up;
        break;
      default:
        cardColor = Colors.red[700]!;
        icon = Icons.warning;
    }

    return Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ));
  }

  void _generateAndDownloadReport() async {
    try {
      // Show beautiful loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[700]!.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Generating Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Please wait while we create your report...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.blue[800],
          duration: const Duration(seconds: 30), // Long duration for generation
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      final pdfBytes = await _eventService.generatePerformanceReportPDF(widget.userId);

      // Dismiss the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Save and share the PDF
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/performance_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);

      // Print/share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
      );

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Report Generated!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your report is ready to view and share',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // Dismiss loading snackbar if there's an error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Generation Failed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Failed to generate report: ${e.toString()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to avoid memory leaks.
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
            _loadEvents();
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
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          Event event = events[index];
                          return _buildEventCard(event, true);
                        },
                      ),
                    ),
                    if (events.isNotEmpty) 
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _showDailyStatistics(context, events),
                          icon: const Icon(Icons.bar_chart, color: Colors.white),
                          label: const Text('Rate my performance', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      )
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final statusOptions = ['All', 'to do', 'in progress', 'done', 'expired'];

    return Column(
      children: [
        // Only show search/filter and generate button if there are events
        FutureBuilder<List<Event>>(
          future: _allEventsFuture,
          builder: (context, snapshot) {
            final hasEvents = snapshot.hasData && snapshot.data!.isNotEmpty;

            if (!hasEvents) {
              return const SizedBox.shrink(); // Hide everything if no events
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
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
                      const SizedBox(width: 8),
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (String newValue) {
                            setState(() {
                              _selectedStatusFilter = newValue;
                            });
                          },
                          itemBuilder: (BuildContext context) {
                            return statusOptions.map((String choice) {
                              return PopupMenuItem<String>(
                                value: choice,
                                child: Text(
                                  choice[0].toUpperCase() + choice.substring(1),
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_list, color: Colors.blue[700]),
                                if (_selectedStatusFilter != 'All') ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedStatusFilter[0].toUpperCase() + _selectedStatusFilter.substring(1),
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Generate Report Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _generateAndDownloadReport,
                    icon: Icon(Icons.assessment, color: Colors.white),
                    label: Text('Generate Performance Report', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        Expanded(
          child: FutureBuilder<List<Event>>(
            future: _allEventsFuture,
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
                      const SizedBox(height: 8),
                      Text(
                        'Create your first event to get started!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final allEvents = snapshot.data!;

                List<Event> statusFilteredEvents;
                if (_selectedStatusFilter == 'All') {
                  statusFilteredEvents = allEvents;
                } else {
                  statusFilteredEvents = allEvents.where((event) => event.status == _selectedStatusFilter).toList();
                }

                final filteredEvents = _eventService.filterEvents(statusFilteredEvents, _searchController.text);

                filteredEvents.sort((a, b) {
                  final aDeadline = DateFormat('yyyy-MM-dd HH:mm').parse('${a.deadlineDate} ${a.deadlineTime}');
                  final bDeadline = DateFormat('yyyy-MM-dd HH:mm').parse('${b.deadlineDate} ${b.deadlineTime}');
                  return aDeadline.compareTo(bDeadline);
                });

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.blue[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
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
    final isExpired = event.status == 'expired';
    final isDone = event.status == 'done';

    Color cardColor = Colors.white;
    if (isExpired) {
      cardColor = Colors.red[100]!;
    } else if (isDone) {
      cardColor = Colors.green[100]!;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
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
            _loadEvents();
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
                  Icon(
                    _getTypeIcon(event.type), 
                    color: isExpired ? Colors.red[700] : (isDone ? Colors.green[700] : Colors.blue[600]), 
                    size: 24
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.red[900] : (isDone ? Colors.green[900] : Colors.blue[900]),
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
                    style: TextStyle(color: isExpired ? Colors.red[800] : (isDone ? Colors.green[800] : Colors.grey[700])),
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
                        color: isExpired ? Colors.red[700] : (isDone ? Colors.green[700] : Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCalendarView ? event.deadlineTime : 'Deadline: ${event.deadlineDate}',
                        style: TextStyle(color: isExpired ? Colors.red[800] : (isDone ? Colors.green[800] : Colors.grey[600]), fontSize: 13),
                      ),
                    ],
                  ),
                  if (!isCalendarView) // Only show time on the right for List view
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: isExpired ? Colors.red[700] : (isDone ? Colors.green[700] : Colors.grey[600])),
                        const SizedBox(width: 4),
                        Text(
                          event.deadlineTime,
                          style: TextStyle(color: isExpired ? Colors.red[800] : (isDone ? Colors.green[800] : Colors.grey[600]), fontSize: 13),
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
