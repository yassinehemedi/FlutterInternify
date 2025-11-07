import 'package:flutter/material.dart';
import 'package:analog_clock/analog_clock.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/EventService.dart';
import 'update_event_screen.dart';

class EventScreen extends StatefulWidget {
  final Event event;

  const EventScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventService _eventService = EventService();
  bool _isDeleting = false;
  late Event _currentEvent;
  bool _hasBeenUpdated = false; // Flag to track updates

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

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

  Widget _buildDateTimeCard(String label, String date, String time) {
    final dateTime = DateFormat('yyyy-MM-dd HH:mm').parse('$date $time');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, color: Colors.blue[900], fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          width: 100,
          child: AnalogClock(
            datetime: dateTime,
            isLive: false,
            decoration: BoxDecoration(
              border: Border.all(width: 2.0, color: Colors.blue[700]!),
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            width: 100.0,
            height: 100.0,
            hourHandColor: Colors.blue[900]!,
            minuteHandColor: Colors.blue[700]!,
            numberColor: Colors.blue[800]!,
            showNumbers: true,
            showAllNumbers: true,
            textScaleFactor: 1.4,
            showTicks: true,
            tickColor: Colors.grey[300]!,
            showDigitalClock: false,
            showSecondHand: false,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 16, 
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      await _eventService.deleteEvent(_currentEvent.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh the previous screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_currentEvent.status);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasBeenUpdated);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Event'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(_hasBeenUpdated),
          ),
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[700]!, Colors.blue[50]!],
              stops: const [0.0, 0.4],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  _currentEvent.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(_getTypeIcon(_currentEvent.type), color: Colors.blue[600], size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Type: ${_currentEvent.type.toUpperCase()}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
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
                                      _currentEvent.status,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              if (_currentEvent.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(_currentEvent.description, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),
                                ),
                              const Divider(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDateTimeCard(
                                        'Created',
                                        _currentEvent.creationDate,
                                        _currentEvent.creationTime,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDateTimeCard(
                                        'Deadline',
                                        _currentEvent.deadlineDate,
                                        _currentEvent.deadlineTime,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateEventScreen(event: _currentEvent),
                                  ),
                                );
                                if (result == true) {
                                  _hasBeenUpdated = true; // Set the flag
                                  final updatedEvent = await _eventService.getEventById(_currentEvent.id!);
                                  if (updatedEvent != null) {
                                    setState(() {
                                      _currentEvent = updatedEvent;
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Update'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                                side: BorderSide(color: Colors.blue[700]!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isDeleting ? null : _deleteEvent,
                              icon: _isDeleting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.delete_outline, color: Colors.white),
                              label: const Text('Delete', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
  }
}
