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
      onUpgrade: _upgradeDB,
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


    // Internship demands table (mirrors reclamations structure but uses duration/companyPreference)
    await db.execute('''
  CREATE TABLE internship_demands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    duration TEXT NOT NULL,
    companyPreference TEXT,
    companyId INTEGER,
    domain TEXT,
    status TEXT NOT NULL DEFAULT "En cours",
    userId INTEGER NOT NULL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT,
    attachments TEXT,
    feedback TEXT,
    FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
  )
''');

    // In-app notifications table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS in_app_notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER,
      title TEXT,
      body TEXT,
      data TEXT,
      isRead INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    )
    ''');
    // parsed_cvs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parsed_cvs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        demandId INTEGER NOT NULL,
        parsedJson TEXT NOT NULL,
        contactEmail TEXT,
        contactPhone TEXT,
        technicalSkills TEXT,
        nonTechnicalSkills TEXT,
        summary TEXT,
        parsedAt TEXT NOT NULL,
        parsedBy INTEGER,
        verified INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(demandId) REFERENCES internship_demands(id) ON DELETE CASCADE
      )
    ''');


    await db.execute('''
    CREATE TABLE contracts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    jobSeekerId INTEGER NOT NULL,
    enterpriseId INTEGER NOT NULL,
    startDate TEXT NOT NULL,
    endDate TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pending',
    description TEXT,
    contractType TEXT,
    pdfPath TEXT NOT NULL,
    signaturePath TEXT,  -- ✅ path (or base64) for signature image
    FOREIGN KEY(jobSeekerId) REFERENCES job_seekers(id) ON DELETE CASCADE,
    FOREIGN KEY(enterpriseId) REFERENCES enterprises(id) ON DELETE CASCADE
  )
''');
    await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('task', 'meeting', 'report')),
      creation_date TEXT NOT NULL,
      creation_time TEXT NOT NULL,
      deadline_date TEXT NOT NULL,
      deadline_time TEXT NOT NULL,
      status TEXT NOT NULL CHECK(status IN ('to do', 'in progress', 'done', 'expired')),
      userId INTEGER NOT NULL,
      FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');


    // Offers table (for fresh installs)
    await db.execute('''
      CREATE TABLE offers (
        id_offer INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        image TEXT,
        category TEXT,
        expiresAt TEXT,
        createdAt TEXT NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Applications table: jobseekers apply to offers
    await db.execute('''
      CREATE TABLE applications (
        id_application INTEGER PRIMARY KEY AUTOINCREMENT,
        cv_file TEXT,
        motivational_message TEXT,
        status TEXT NOT NULL DEFAULT 'Pending',
        createdAt TEXT NOT NULL,
        userId INTEGER NOT NULL,
        offerId INTEGER NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(offerId) REFERENCES offers(id_offer) ON DELETE CASCADE
      )
    ''');

    // Comments table: any user can comment on an offer
    await db.execute('''
      CREATE TABLE comments (
        id_comment INTEGER PRIMARY KEY AUTOINCREMENT,
        comment_content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        userId INTEGER NOT NULL,
        offerId INTEGER NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(offerId) REFERENCES offers(id_offer) ON DELETE CASCADE
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id_notification INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        recipientId INTEGER NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        offerId INTEGER,
        FOREIGN KEY(recipientId) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY(offerId) REFERENCES offers(id_offer) ON DELETE SET NULL
      )
    ''');

    // Comment reports table
    await db.execute('''
      CREATE TABLE comment_reports (
        id_report INTEGER PRIMARY KEY AUTOINCREMENT,
        commentId INTEGER NOT NULL,
        reporterId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(commentId) REFERENCES comments(id_comment) ON DELETE CASCADE,
        FOREIGN KEY(reporterId) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(commentId, reporterId)
      )
    ''');


  }

  /// ✅ UPGRADE database (pour les mises à jour)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Si l'ancienne version est 1 et la nouvelle est 2
    if (oldVersion < 2) {
      // Ajouter la table contracts si elle n'existe pas déjà




    }

    // Si tu ajoutes d'autres tables plus tard:
    // if (oldVersion < 3) {
    //   await db.execute('CREATE TABLE ...');
    // }
  }

  /// Delete expired offers (returns number of deleted rows)
  Future<int> purgeExpiredOffers() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.delete(
      'offers',
      where: 'expiresAt IS NOT NULL AND expiresAt <= ?',
      whereArgs: [now],
    );
  }


  /// Delete entire database (useful for testing)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'internify.db');

    // Close database first
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Delete the database file
    await databaseFactory.deleteDatabase(path);
    print('✅ Database deleted successfully');
  }


  // ==================== CLOSE DATABASE ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
