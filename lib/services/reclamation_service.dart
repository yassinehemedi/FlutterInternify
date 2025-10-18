import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/reclamation.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:printing/printing.dart';

class ReclamationService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a new reclamation
  Future<int> insertReclamation(Reclamation reclamation) async {
    final db = await _dbHelper.database;
    return await db.insert('reclamations', reclamation.toMap());
  }

  // Update an existing reclamation
  Future<int> updateReclamation(Reclamation reclamation) async {
    final db = await _dbHelper.database;
    return await db.update(
      'reclamations',
      reclamation.toMap(),
      where: 'id = ?',
      whereArgs: [reclamation.id],
    );
  }

  // Delete a reclamation
  Future<int> deleteReclamation(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'reclamations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fetch all reclamations for a specific user
  Future<List<Reclamation>> getReclamationsByUserId(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Reclamation.fromMap(maps[i]);
    });
  }

  // Fetch a single reclamation by ID
  Future<Reclamation?> getReclamationById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Reclamation.fromMap(maps.first);
    }
    return null;
  }

  // Get reclamations count for a user
  Future<int> getReclamationsCount(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reclamations WHERE userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get reclamations by status for a user
  Future<List<Reclamation>> getReclamationsByStatus(
      int userId, String status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      where: 'userId = ? AND status = ?',
      whereArgs: [userId, status],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Reclamation.fromMap(maps[i]);
    });
  }

  // Save reclamation (insert or update) - Business Logic
  Future<Map<String, dynamic>> saveReclamation({
    int? id,
    required String title,
    required String description,
    required String category,
    required int userId,
    DateTime? createdAt,
    String? sentiment,      // 🧠 NEW
    String? priority,       // 🧠 NEW
  }) async {
    try {
      final reclamation = Reclamation(
        id: id,
        title: title,
        description: description,
        category: category,
        status: 'En cours',
        userId: userId,
        createdAt: createdAt ?? DateTime.now(),
        sentiment: sentiment,    // 🧠 NEW
        priority: priority,      // 🧠 NEW
      );

      if (id == null) {
        final result = await insertReclamation(reclamation);
        return {'success': result > 0, 'message': 'Réclamation ajoutée avec succès'};
      } else {
        final result = await updateReclamation(reclamation);
        return {'success': result > 0, 'message': 'Réclamation modifiée avec succès'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }
  // Delete reclamation - Business Logic
  Future<Map<String, dynamic>> removeReclamation(int id) async {
    try {
      final result = await deleteReclamation(id);
      return {
        'success': result > 0,
        'message': result > 0
            ? 'Réclamation supprimée avec succès'
            : 'Erreur lors de la suppression'
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Get status color - Business Logic
  String getStatusColorName(String status) {
    switch (status.toLowerCase()) {
      case 'en cours':
        return 'blue';
      case 'terminée':
        return 'green';
      default:
        return 'grey';
    }
  }

  // Format date - Business Logic
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Get categories list
  List<String> getCategories() {
    return [
      'Technique',
      'Facturation',
      'Service',
      'Livraison',
      'Qualité',
      'Autre',
    ];
  }

  // Validate title
  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le titre est obligatoire';
    }
    if (value.trim().length < 5) {
      return 'Le titre doit contenir au moins 5 caractères';
    }
    if (value.trim().length > 100) {
      return 'Le titre ne peut pas dépasser 100 caractères';
    }
    return null;
  }

  // Validate description
  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La description est obligatoire';
    }
    if (value.trim().length < 10) {
      return 'La description doit contenir au moins 10 caractères';
    }
    if (value.trim().length > 500) {
      return 'La description ne peut pas dépasser 500 caractères';
    }
    return null;
  }

  // Validate category
  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez sélectionner une catégorie';
    }
    return null;
  }


  // Updated method to accept actual statistics data
  Future<void> exportStatsAsPdf(
      BuildContext context, {
        required Map<String, dynamic> statistics,
      }) async {
    final pdf = pw.Document();

    // Extract data from statistics
    final total = statistics['total'] as int;
    final statusData = statistics['statusChartData'] as List<Map<String, dynamic>>;
    final categoryData = statistics['categoryChartData'] as List<Map<String, dynamic>>;

    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Text(
              'Rapport des Statistiques des Réclamations',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 10),
          pw.Text(
            'Date du rapport : $formattedDate',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          // Total Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.blue200, width: 2),
            ),
            child: pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'TOTAL RÉCLAMATIONS',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '$total',
                    style: pw.TextStyle(
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // Status Section
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '📊 Répartition par Statut',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Statut', 'Nombre', 'Pourcentage'],
                  data: statusData.map((item) {
                    return [
                      item['status'],
                      item['count'].toString(),
                      '${item['percentage']}%',
                    ];
                  }).toList(),
                  cellStyle: pw.TextStyle(fontSize: 12),
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // Category Section
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '🏷️ Répartition par Catégorie',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                  ),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Catégorie', 'Nombre', 'Pourcentage'],
                  data: categoryData.map((item) {
                    return [
                      item['category'],
                      item['count'].toString(),
                      '${item['percentage']}%',
                    ];
                  }).toList(),
                  cellStyle: pw.TextStyle(fontSize: 12),
                  cellPadding: const pw.EdgeInsets.all(8),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Paragraph(
            text: "Ce rapport présente les statistiques des réclamations à la date du $formattedDate.",
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    try {
      // Save in Downloads folder (Android)
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName = 'stats_reclamations_$formattedDate.pdf'.replaceAll('/', '-');
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('✅ PDF sauvegardé dans le dossier Téléchargements !'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      print('✅ PDF saved at: $filePath');
    } catch (e) {
      print('❌ Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('❌ Erreur : $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }


}