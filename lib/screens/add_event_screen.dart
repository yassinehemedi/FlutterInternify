import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/EventService.dart';

class AddEventScreen extends StatefulWidget {
  final int userId;

  const AddEventScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AddEventScreenState createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'task';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        // Force 24-hour format
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

  Widget _buildEventTypeSelector() {
    const types = {
      'task': Icons.task_alt,
      'meeting': Icons.people_outline,
      'report': Icons.article_outlined,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: types.entries.map((entry) {
        final type = entry.key;
        final icon = entry.value;
        final isSelected = _selectedType == type;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
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
                    type[0].toUpperCase() + type.substring(1),
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
      }).toList(),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create a New Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title *',
                            hintText: 'e.g., Team Meeting',
                            prefixIcon: Icon(Icons.title, color: Colors.blue[700]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.blue[50],
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g., Discuss project progress',
                            prefixIcon: Icon(Icons.description, color: Colors.blue[700]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.blue[50],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Event Type *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        const SizedBox(height: 8),
                        _buildEventTypeSelector(),
                        const SizedBox(height: 24),
                        Text('Deadline *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date',
                                    prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[700]),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                  ),
                                  child: Text(_selectedDate == null ? 'Select Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickTime(context),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Time',
                                    prefixIcon: Icon(Icons.access_time, color: Colors.blue[700]),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.blue[50],
                                  ),
                                  child: Text(
                                    _selectedTime == null
                                        ? 'Select Time'
                                        : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedDate == null || _selectedTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a deadline date and time'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setState(() => _isLoading = true);
                              final now = DateTime.now();
                              final event = Event(
                                title: _titleController.text,
                                description: _descriptionController.text,
                                type: _selectedType,
                                creationDate: DateFormat('yyyy-MM-dd').format(now),
                                creationTime: DateFormat('HH:mm').format(now),
                                deadlineDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
                                deadlineTime: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                                status: 'to do',
                                userId: widget.userId,
                              );
                              await _eventService.addEvent(event);
                              setState(() => _isLoading = false);
                              Navigator.of(context).pop(true); // Return true to indicate success
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Event'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.blue[700]!),
                          ),
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
