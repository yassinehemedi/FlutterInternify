import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/entreprise_model.dart';
import '../models/jobseeker_model.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Database Helper
/// Manages SQLite database operations for user management, job seekers, and enterprises
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('internify.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create all tables
  Future<void> _createDB(Database db, int version) async {
    // Users table with role
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      isVerified INTEGER NOT NULL DEFAULT 0,
      phone TEXT,
      verificationToken TEXT,
      tokenCreatedAt INTEGER,
      role TEXT NOT NULL  -- "job_seeker" or "enterprise"
    )
  ''');

    // Job seekers table (one-to-one with User)
    await db.execute('''
      CREATE TABLE job_seekers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL UNIQUE,
        resumeUrl TEXT,
        cvDescription TEXT,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Enterprises table (one-to-one with User)
    await db.execute('''
      CREATE TABLE enterprises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL UNIQUE,
        companyName TEXT,
        companyDescription TEXT,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
  CREATE TABLE reclamations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    priority TEXT NOT NULL,
    sentiment TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT "Pending",
    userId INTEGER NOT NULL,  -- INTEGER to match users.id
    createdAt TEXT NOT NULL,
    FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
  )
''');

  }



  // ==================== CLOSE DATABASE ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
