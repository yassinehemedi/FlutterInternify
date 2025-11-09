import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/application_model.dart';

class ApplicationService {
  static final ApplicationService instance = ApplicationService._init();
  ApplicationService._init();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<ApplicationModel?> createApplication(ApplicationModel app) async {
    final db = await _db;
    final id = await db.insert('applications', app.toMap());
    return app.copyWith(idApplication: id);
  }

  Future<ApplicationModel?> getApplicationById(int id) async {
    final db = await _db;
    final res = await db.query('applications', where: 'id_application = ?', whereArgs: [id]);
    if (res.isNotEmpty) return ApplicationModel.fromMap(res.first);
    return null;
  }

  Future<List<ApplicationModel>> getApplicationsByOfferId(int offerId) async {
    final db = await _db;
    final res = await db.query('applications', where: 'offerId = ?', whereArgs: [offerId], orderBy: 'createdAt DESC');
    return res.map((m) => ApplicationModel.fromMap(m)).toList();
  }

  Future<List<ApplicationModel>> getApplicationsByUserId(int userId) async {
    final db = await _db;
    final res = await db.query('applications', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return res.map((m) => ApplicationModel.fromMap(m)).toList();
  }

  Future<int> updateApplication(ApplicationModel app) async {
    final db = await _db;
    return await db.update('applications', app.toMap(), where: 'id_application = ?', whereArgs: [app.idApplication]);
  }

  Future<int> deleteApplication(int id) async {
    final db = await _db;
    return await db.delete('applications', where: 'id_application = ?', whereArgs: [id]);
  }
}
