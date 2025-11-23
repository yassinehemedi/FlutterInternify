import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/EventService.dart';

class UpdateEventScreen extends StatefulWidget {
  final Event event;

  const UpdateEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  _UpdateEventScreenState createState() => _UpdateEventScreenState();
}

class _UpdateEventScreenState extends State<UpdateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedStatus;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _selectedType = widget.event.type;
    _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.event.deadlineDate);
    _selectedTime = TimeOfDay(
      hour: int.parse(widget.event.deadlineTime.split(':')[0]),
      minute: int.parse(widget.event.deadlineTime.split(':')[1]),
    );
    _selectedStatus = widget.event.status;
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Prevent selecting past dates
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Widget _buildSelectorCard(String value, String selectedValue, IconData icon, Function(String) onSelect) {
    final isSelected = value == selectedValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.blue[800] : Colors.grey[600], size: 28),
              const SizedBox(height: 8),
              Text(
                value[0].toUpperCase() + value.substring(1),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue[900] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[50]!],
            stops: const [0.0, 0.2],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Edit Event Details',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(labelText: 'Title *', prefixIcon: Icon(Icons.title, color: Colors.blue[700]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.blue[50]),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Title is required';
                            }
                            if (value.length < 5) {
                              return 'Title must be at least 5 characters long';
                            }
                            if (value.length > 50) {
                              return 'Title cannot exceed 50 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description, color: Colors.blue[700]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.blue[50]),
                          keyboardType: TextInputType.multiline,
                          minLines: 3,
                          maxLines: null,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Description is required';
                            }
                            if (value.length < 10) {
                              return 'Description must be at least 10 characters long';
                            }
                            if (value.length > 100) {
                              return 'Description cannot exceed 100 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text('Event Type *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildSelectorCard('task', _selectedType, Icons.task_alt, (val) => setState(() => _selectedType = val)),
                            _buildSelectorCard('meeting', _selectedType, Icons.people_outline, (val) => setState(() => _selectedType = val)),
                            _buildSelectorCard('report', _selectedType, Icons.article_outlined, (val) => setState(() => _selectedType = val)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Status *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                             _buildSelectorCard('to do', _selectedStatus, Icons.pending_actions, (val) => setState(() => _selectedStatus = val)),
                            _buildSelectorCard('in progress', _selectedStatus, Icons.directions_run, (val) => setState(() => _selectedStatus = val)),
                            _buildSelectorCard('done', _selectedStatus, Icons.check_circle, (val) => setState(() => _selectedStatus = val)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Deadline *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[700]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.blue[50]),
                                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(labelText: 'Time', prefixIcon: Icon(Icons.access_time, color: Colors.blue[700]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.blue[50]),
                                  child: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              final title = _titleController.text.trim();
                              final exists = await _eventService.eventTitleExists(title, widget.event.userId, currentEventId: widget.event.id);
                              if (exists) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Duplicate Title', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: const Text(
                                      'An event with this title already exists.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              final deadline = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
                              if (deadline.isBefore(DateTime.now())) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Invalid Deadline', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: const Text(
                                      'Deadline cannot be in the past.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);
                              final updatedEvent = Event(
                                id: widget.event.id,
                                title: title,
                                description: _descriptionController.text,
                                type: _selectedType,
                                creationDate: widget.event.creationDate,
                                creationTime: widget.event.creationTime,
                                deadlineDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                                deadlineTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                status: _selectedStatus,
                                userId: widget.event.userId,
                              );
                              await _eventService.updateEvent(updatedEvent);
                              setState(() => _isLoading = false);
                              Navigator.of(context).pop(true);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.blue[700], padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.blue[700]!)),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
