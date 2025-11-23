import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
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

  Map<String, dynamic> calculateDailyStatistics(List<Event> events) {
    if (events.isEmpty) {
      return {
        'typePercentages': {},
        'inProgressPercentage': 0.0,
        'donePercentage': 0.0,
        'motivationalMessage': 'No events for this day.',
        'typeCounts': {},
      };
    }

    int totalEvents = events.length;
    Map<String, int> typeCounts = {'task': 0, 'meeting': 0, 'report': 0};
    int inProgressCount = 0;
    int doneCount = 0;

    for (var event in events) {
      if (typeCounts.containsKey(event.type)) {
        typeCounts[event.type] = typeCounts[event.type]! + 1;
      }
      if (event.status == 'in progress') {
        inProgressCount++;
      }
      if (event.status == 'done') {
        doneCount++;
      }
    }

    Map<String, double> typePercentages = typeCounts.map((key, value) => MapEntry(key, (value / totalEvents) * 100));

    double inProgressPercentage = (inProgressCount / totalEvents) * 100;
    double donePercentage = (doneCount / totalEvents) * 100;

    String motivationalMessage;
    if (donePercentage > 90) {
      motivationalMessage = 'Very Good!';
    } else if (donePercentage >= 70) {
      motivationalMessage = 'A little bit left!';
    } else {
      motivationalMessage = 'You need to do more!';
    }

    return {
      'typePercentages': typePercentages,
      'inProgressPercentage': inProgressPercentage,
      'donePercentage': donePercentage,
      'motivationalMessage': motivationalMessage,
      'typeCounts': typeCounts,
    };
  }

  Future<Uint8List> generatePerformanceReportPDF(int userId) async {
    try {
      // Get user data and events
      final events = await getEvents(userId);
      final user = await UserService.instance.getUserById(userId);
      final completedEvents = events.where((e) => e.status == 'done').length;
      final totalEvents = events.length;
      final pendingEvents = events.where((e) => e.status == 'in progress').toList();
      final double completionRate = totalEvents > 0 ? (completedEvents / totalEvents * 100) : 0;

      // Generate analysis with Gemini
      final geminiAnalysis = await _getGeminiAnalysis(
        completedEvents: completedEvents,
        totalEvents: totalEvents,
        pendingEvents: pendingEvents,
        completionRate: completionRate,
      );

      // Create PDF
      return await _createPDF(
        userName: user?.name ?? 'User',
        events: events,
        completedEvents: completedEvents,
        totalEvents: totalEvents,
        pendingEvents: pendingEvents,
        completionRate: completionRate,
        geminiAnalysis: geminiAnalysis,
      );
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  Future<String> _getGeminiAnalysis({
    required int completedEvents,
    required int totalEvents,
    required List<Event> pendingEvents,
    required double completionRate,
  }) async {
    final prompt = """
  Analyze this user's task performance and generate a motivational report in 150-200 words:
  
  Statistics:
  - Total Tasks: $totalEvents
  - Completed Tasks: $completedEvents
  - Completion Rate: ${completionRate.toStringAsFixed(1)}%
  - Pending Tasks: ${pendingEvents.length}
  
  Please provide:
  1. A brief performance summary
  2. Analysis of their productivity level
  3. Motivational advice based on their progress
  4. 2-3 specific suggestions for improvement
  
  Keep it professional, constructive and motivational. Focus on actionable insights.
  """;

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyC_E7qqdjpyfCZpeNxa8kIfys5ibRk-bxw'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': prompt}]
        }]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      return "Performance analysis unavailable. Focus on completing your pending tasks to improve productivity.";
    }
  }

  Future<Uint8List> _createPDF({
    required String userName,
    required List<Event> events,
    required int completedEvents,
    required int totalEvents,
    required List<Event> pendingEvents,
    required double completionRate,
    required String geminiAnalysis,
  }) async {
    final pdf = pw.Document();
    final tasksPerPage = 15;

    // First page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - using simple text instead of Header widget
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Performance Report',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Text('Report for: $userName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // Statistics Section
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Quick Stats', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Tasks', totalEvents.toString(), PdfColors.blue700),
                        _buildStatItem('Completed', completedEvents.toString(), PdfColors.green700),
                        _buildStatItem('Pending', pendingEvents.length.toString(), PdfColors.orange700),
                        _buildStatItem('Completion', '${completionRate.toStringAsFixed(1)}%', PdfColors.purple700),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Gemini Analysis Section
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Performance Analysis', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                    pw.SizedBox(height: 8),
                    pw.Text(geminiAnalysis, style: pw.TextStyle(fontSize: 10, lineSpacing: 1.3)),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Pending Tasks Preview
              if (pendingEvents.isNotEmpty) ...[
                pw.Text('Pending Tasks (${pendingEvents.length} total)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.SizedBox(height: 8),
                if (pendingEvents.length > 5)
                  pw.Text('Showing first 5 tasks. See next page for complete list.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                _buildTasksTable(pendingEvents.take(5).toList()),
              ],
            ],
          );
        },
      ),
    );

    // Additional pages for remaining tasks
    if (pendingEvents.length > 5) {
      final remainingTasks = pendingEvents.skip(5).toList();

      for (var i = 0; i < remainingTasks.length; i += tasksPerPage) {
        final pageTasks = remainingTasks.skip(i).take(tasksPerPage).toList();
        final pageNumber = (i ~/ tasksPerPage) + 2;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Simple header for continuation pages
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Pending Tasks - Continued',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.Text(
                        'Page $pageNumber',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 15),
                  _buildTasksTable(pageTasks),

                  // Footer
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: double.infinity,
                    padding: pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Report for: $userName - Page $pageNumber',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    return await pdf.save();
  }

// Helper method to build the tasks table
  // Helper method to build the tasks table
  // Helper method to build the tasks table
  pw.Widget _buildTasksTable(List<Event> tasks) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: pw.FlexColumnWidth(3), // Task name
        1: pw.FlexColumnWidth(1), // Type
        2: pw.FlexColumnWidth(1.5), // Deadline
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        // Table header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Task Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Deadline', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        // Table rows
        ...tasks.map((event) => pw.TableRow(
          children: [
            pw.Container(
              padding: pw.EdgeInsets.all(6),
              height: 25, // Fixed height for consistency
              child: pw.Text(
                _truncateText(event.title, 35),
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text(
                event.type,
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(6),
              child: pw.Text(
                '${event.deadlineDate}\n${event.deadlineTime}',
                style: pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        )).toList(),
      ],
    );
  }

// Helper method to truncate long text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }

  pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

}
