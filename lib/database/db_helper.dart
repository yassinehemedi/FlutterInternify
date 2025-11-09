import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 6,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Upgrade path: v1 -> v2 (offers), v2 -> v3 (applications/comments)
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE offers (
              id_offer INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              image TEXT,
              category TEXT,
              createdAt TEXT NOT NULL,
              userId INTEGER NOT NULL,
              FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 3) {
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
        }

        if (oldVersion < 4) {
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
        }

        if (oldVersion < 5) {
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
        // v6: add expiresAt column to offers for automatic expiry
        if (oldVersion < 6) {
          try {
            await db.execute('ALTER TABLE offers ADD COLUMN expiresAt TEXT');
          } catch (_) {
            // ignore if column already exists or other issue
          }
        }
      },
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

  // ==================== CLOSE DATABASE ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
