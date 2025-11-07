import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/event.dart';

class EventService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Add an event
  Future<int> addEvent(Event event) async {
    final db = await _dbHelper.database;
    return await db.insert('events', event.toMap());
  }

  // Get a single event by its ID
  Future<Event?> getEventById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }

  // Get all events for a specific user
  Future<List<Event>> getEvents(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  // Get events for a specific user on a specific date
  Future<List<Event>> getEventsByDate(int userId, String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'userId = ? AND deadline_date = ?',
      whereArgs: [userId, date],
    );
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  // Update an event
  Future<int> updateEvent(Event event) async {
    final db = await _dbHelper.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  // Delete an event
  Future<int> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Check if an event title exists for a user
  Future<bool> eventTitleExists(String title, int userId, {int? currentEventId}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;
    if (currentEventId != null) {
      // For updates, ignore the current event's ID
      maps = await db.query(
        'events',
        where: 'title = ? AND userId = ? AND id != ?',
        whereArgs: [title, userId, currentEventId],
        limit: 1,
      );
    } else {
      // For adds, just check title and userId
      maps = await db.query(
        'events',
        where: 'title = ? AND userId = ?',
        whereArgs: [title, userId],
        limit: 1,
      );
    }
    return maps.isNotEmpty;
  }

  // Filter events based on a search query
  List<Event> filterEvents(List<Event> events, String query) {
    if (query.isEmpty) {
      return events;
    }
    final lowerCaseQuery = query.toLowerCase();
    return events.where((event) {
      final titleMatch = event.title.toLowerCase().contains(lowerCaseQuery);
      final descriptionMatch = event.description.toLowerCase().contains(lowerCaseQuery);
      final typeMatch = event.type.toLowerCase().contains(lowerCaseQuery);
      final statusMatch = event.status.toLowerCase().contains(lowerCaseQuery);
      return titleMatch || descriptionMatch || typeMatch || statusMatch;
    }).toList();
  }
}
