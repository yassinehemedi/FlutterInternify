import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/reclamation.dart';

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
}