import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../database/db_helper.dart';
import '../models/event.dart';
import '../models/user_model.dart';
import 'UserService.dart';

class EventService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Brevo SMTP Configuration
  static const String _smtpHost = 'smtp-relay.brevo.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = '996b2d001@smtp-brevo.com';
  static const String _smtpPassword = 'AZy5vzX8gCYxtDJM';
  static const String _senderEmail = 'yassinehemedi6@gmail.com';
  static const String _senderName = 'Internify Team';

  // Private method to send the expiration email
  Future<void> _sendEventExpiredEmail({
    required String recipientEmail,
    required String recipientName,
    required Event event,
  }) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Event Deadline Passed: ${event.title}'
        ..html = _getExpiredEmailTemplate(recipientName, event);

      await send(message, smtpServer);
      print('✅ Expiration email sent successfully to $recipientEmail for event "${event.title}" ');
    } catch (e) {
      print('❌ Failed to send expiration email: $e');
    }
  }

  // HTML template for event expiration
  static String _getExpiredEmailTemplate(String recipientName, Event event) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 20px auto; background: #fff; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        .header { background: #d9534f; color: white; padding: 20px; text-align: center; border-top-left-radius: 8px; border-top-right-radius: 8px; }
        .content { padding: 30px; }
        .footer { padding: 20px; text-align: center; font-size: 12px; color: #888; background: #f7f7f7; border-bottom-left-radius: 8px; border-bottom-right-radius: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Event Expired</h1>
        </div>
        <div class="content">
            <p>Hi <strong>$recipientName</strong>,</p>
            <p>This is an automated notification to let you know that the deadline for one of your events has passed.</p>
            <h3>Event Details:</h3>
            <ul>
                <li><strong>Title:</strong> ${event.title}</li>
                <li><strong>Deadline:</strong> ${event.deadlineDate} at ${event.deadlineTime}</li>
            </ul>
            <p>The status for this event has been automatically updated to "Expired".</p>
            <p>Best regards,<br>The Internify Team</p>
        </div>
        <div class="footer">
            <p>&copy; 2025 Internify. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }


  Future<int> addEvent(Event event) async {
    final db = await _dbHelper.database;
    return await db.insert('events', event.toMap());
  }

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

  Future<int> updateEvent(Event event) async {
    final db = await _dbHelper.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> eventTitleExists(String title, int userId, {int? currentEventId}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;
    if (currentEventId != null) {
      maps = await db.query(
        'events',
        where: 'title = ? AND userId = ? AND id != ?',
        whereArgs: [title, userId, currentEventId],
        limit: 1,
      );
    } else {
      maps = await db.query(
        'events',
        where: 'title = ? AND userId = ?',
        whereArgs: [title, userId],
        limit: 1,
      );
    }
    return maps.isNotEmpty;
  }

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

  Future<List<Event>> updateExpiredEvents(int userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final List<Event> events = await getEvents(userId);
    final User? user = await UserService.instance.getUserById(userId);

    List<Event> newlyExpiredEvents = [];

    if (user == null) {
      return newlyExpiredEvents; // Return empty list if user not found
    }

    final batch = db.batch();

    for (final event in events) {
      if (event.status != 'done' && event.status != 'expired') {
        final deadline = DateFormat('yyyy-MM-dd HH:mm').parse('${event.deadlineDate} ${event.deadlineTime}');
        if (deadline.isBefore(now)) {
          batch.update(
            'events',
            {'status': 'expired'},
            where: 'id = ?',
            whereArgs: [event.id],
          );
          newlyExpiredEvents.add(event);
        }
      }
    }

    if (newlyExpiredEvents.isNotEmpty) {
      await batch.commit(noResult: true);
      // Send notifications for the events that just expired
      for (final event in newlyExpiredEvents) {
        await _sendEventExpiredEmail(
          recipientEmail: user.email,
          recipientName: user.name,
          event: event,
        );
      }
    }
    return newlyExpiredEvents;
  }
}
