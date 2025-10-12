
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';
import '../models/jobseeker_model.dart';
import '../models/entreprise_model.dart';
import '../database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static final UserService instance = UserService._init();
  UserService._init();

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // ==================== USER CRUD ====================

  Future<User?> registerUser(User user) async {
    final db = await _db;

    try {
      final id = await db.insert('users', user.toMap());
      final newUser = user.copyWith(id: id);

      // Create job seeker or enterprise record
      if (newUser.role == 'job_seeker') {
        await db.insert('job_seekers', {'userId': newUser.id});
      } else if (newUser.role == 'enterprise') {
        await db.insert('enterprises', {'userId': newUser.id});
      }

      return newUser;
    } catch (e) {
      return null; // Email exists or other error
    }
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await _db;
    final result = await db.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);

    if (result.isNotEmpty) {
      final user = User.fromMap(result.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('currentUserId', user.id!);
      return user;
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _db;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return User.fromMap(result.first);
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await _db;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return User.fromMap(result.first);
    return null;
  }

  Future<int> verifyUser(String email) async {
    final db = await _db;
    return await db.update('users', {'isVerified': 1}, where: 'email = ?', whereArgs: [email]);
  }

  Future<void> updateUser({
    required int userId,
    required String name,
    required String phone,
  }) async {
    final db = await _db;
    await db.update('users', {'name': name, 'phone': phone}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> updateUserPassword({required String email, required String newPassword}) async {
    final db = await _db;
    await db.update('users', {'password': newPassword}, where: 'email = ?', whereArgs: [email]);
  }

  Future<void> deleteUser(int userId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final userList = await txn.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
      if (userList.isEmpty) throw Exception('User not found');
      final role = userList.first['role'] as String?;

      if (role == 'job_seeker') {
        await txn.delete('job_seekers', where: 'userId = ?', whereArgs: [userId]);
      } else if (role == 'enterprise') {
        await txn.delete('enterprises', where: 'userId = ?', whereArgs: [userId]);
      }

      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    });
  }

  Future<List<User>> getAllUsers() async {
    final db = await _db;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<bool> emailExists(String email) async {
    final db = await _db;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty;
  }

  // ==================== JOB SEEKER METHODS ====================

  Future<int> updateJobSeeker({
    required int userId,
    required String resumeUrl,
    required String cvDescription,
  }) async {
    final db = await _db;
    return await db.update(
      'job_seekers',
      {'resumeUrl': resumeUrl, 'cvDescription': cvDescription},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<JobSeeker?> getJobSeekerByUserId(int userId) async {
    final db = await _db;
    final result = await db.query('job_seekers', where: 'userId = ?', whereArgs: [userId]);
    if (result.isNotEmpty) return JobSeeker.fromMap(result.first);
    return null;
  }

  // ==================== ENTERPRISE METHODS ====================

  Future<int> updateEnterprise({
    required int userId,
    required String companyName,
    required String companyDescription,
  }) async {
    final db = await _db;
    return await db.update(
      'enterprises',
      {'companyName': companyName, 'companyDescription': companyDescription},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<Enterprise?> getEnterpriseByUserId(int userId) async {
    final db = await _db;
    final result = await db.query('enterprises', where: 'userId = ?', whereArgs: [userId]);
    if (result.isNotEmpty) return Enterprise.fromMap(result.first);
    return null;
  }
}
