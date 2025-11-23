// filepath: lib/services/internship_demand_service.dart
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/internship_demand.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/notification_service.dart';
import '../services/email_service.dart';
import '../services/UserService.dart';

class InternshipDemandService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String tableName = 'internship_demands';

  // Ensure table exists (used as a defensive fallback at runtime)
  Future<void> _ensureTableExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS internship_demands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        duration TEXT NOT NULL,
        companyPreference TEXT,
        status TEXT NOT NULL DEFAULT "En cours",
        userId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertInternshipDemand(InternshipDemand demand) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert(tableName, demand.toMap());
    } catch (e) {
      // If table missing, create it and retry once
      if (e.toString().contains('no such table')) {
        await _ensureTableExists(db);
        return await db.insert(tableName, demand.toMap());
      }
      rethrow;
    }
  }

  Future<int> updateInternshipDemand(InternshipDemand demand) async {
    final db = await _dbHelper.database;
    return await db.update(tableName, demand.toMap(), where: 'id = ?', whereArgs: [demand.id]);
  }

  Future<int> deleteInternshipDemand(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<InternshipDemand>> getByUserId(int userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(tableName, where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return maps.map((m) => InternshipDemand.fromMap(m)).toList();
  }

  /// Get all demands (used by admin/enterprise read-only view)
  Future<List<InternshipDemand>> getAllDemands() async {
    final db = await _dbHelper.database;
    final maps = await db.query(tableName, orderBy: 'createdAt DESC');
    return maps.map((m) => InternshipDemand.fromMap(m)).toList();
  }

  Future<InternshipDemand?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return InternshipDemand.fromMap(maps.first);
  }

  Future<int> countByUser(int userId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName WHERE userId = ?', [userId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // Get demands for a specific company (for enterprise view)
  Future<List<InternshipDemand>> getForCompany(int companyId, {String? status, String? searchQuery, String? sortBy, String? domain, int? studentId}) async {
    final db = await _dbHelper.database;
    String where = 'companyId = ?';
    final List<Object?> args = [companyId];
    if (status != null && status.isNotEmpty && status != 'Tous') {
      where += ' AND status = ?';
      args.add(status);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where += ' AND (title LIKE ? OR description LIKE ?)';
      args.add('%$searchQuery%');
      args.add('%$searchQuery%');
    }
    if (domain != null && domain.isNotEmpty) {
      where += ' AND domain = ?';
      args.add(domain);
    }
    if (studentId != null) {
      where += ' AND userId = ?';
      args.add(studentId);
    }

    String orderBy = 'createdAt DESC';
    if (sortBy == 'date_asc') orderBy = 'createdAt ASC';
    if (sortBy == 'date_desc') orderBy = 'createdAt DESC';

    final maps = await db.query(tableName, where: where, whereArgs: args, orderBy: orderBy);
    return maps.map((m) => InternshipDemand.fromMap(m)).toList();
  }

  // Change status (accept/reject) with optional feedback, and return success
  Future<bool> changeStatus(int id, String newStatus, {String? feedback}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final data = {
      'status': newStatus,
      'feedback': feedback,
      'updatedAt': now,
    };
    final res = await db.update(tableName, data, where: 'id = ?', whereArgs: [id]);

    // Optionally, send notification/email here (placeholder)
    final demand = await getById(id);
    if (demand != null) {
      NotificationService.instance.notifyStatusChange(demand.userId, newStatus);
      // Try send email to user (if available)
      final userSvc = UserService.instance;
      final user = await userSvc.getUserById(demand.userId);
      if (user != null && user.email.isNotEmpty) {
        await EmailService.sendStatusEmail(recipientEmail: user.email, demand: demand, newStatus: newStatus, feedback: feedback);
      }
    }

    return res > 0;
  }

  // Export demands as PDF (basic)
  Future<void> exportDemandsAsPdf(List<InternshipDemand> demands) async {
    // Simple PDF creation — you can extend/customize as needed
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(build: (ctx) {
      return [
        pw.Header(level: 0, child: pw.Text('Rapport Demandes de Stage', style: pw.TextStyle(fontSize: 22))),
        pw.SizedBox(height: 10),
        pw.ListView.builder(itemCount: demands.length, itemBuilder: (context, idx) {
          final d = demands[idx];
          return pw.Column(children: [pw.Text('${d.title} - ${d.status}'), pw.Text('Utilisateur: ${d.userId}'), pw.Text('Durée: ${d.duration}'), pw.SizedBox(height: 8)]);
        })
      ];
    }));

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'demands_report.pdf');
  }

  // Export demands as CSV and share
  Future<void> exportDemandsAsCsv(List<InternshipDemand> demands) async {
    final buffer = StringBuffer();
    buffer.writeln('id,title,description,duration,status,userId,createdAt,updatedAt,attachments,feedback');
    for (final d in demands) {
      final attachments = d.attachments == null ? '' : d.attachments!.join('|');
      final row = [
        d.id?.toString() ?? '',
        '"${d.title.replaceAll('"', '""')}"',
        '"${d.description.replaceAll('"', '""')}"',
        d.duration,
        d.status,
        d.userId.toString(),
        d.createdAt.toIso8601String(),
        d.updatedAt?.toIso8601String() ?? '',
        '"${attachments.replaceAll('"', '""')}"',
        '"${(d.feedback ?? '').replaceAll('"', '""')}"'
      ].join(',');
      buffer.writeln(row);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/demands_export.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Export des demandes');
  }
}
