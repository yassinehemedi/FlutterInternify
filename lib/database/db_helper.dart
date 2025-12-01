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
    // Defensive: ensure crucial tables exist even if DB came from an older app
    await _ensureAdditionalTables(_database!);
    return _database!;
  }

  // Ensure optional/new tables/columns exist on older DB copies
  Future<void> _ensureAdditionalTables(Database db) async {
    try {
      final res = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='internship_demands'");
      if (res.isEmpty) {
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
    } catch (e) {
      // swallow: we'll attempt upgrades elsewhere
    }
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Handle database upgrades (create new tables as needed)
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // If upgrading from version 1 -> 2, ensure internship_demands table exists
    if (oldVersion < 2) {
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

    // v2 -> v3: add new optional columns
    if (oldVersion < 3) {
      // Safe add columns if they don't exist
      try {
        await db.execute("ALTER TABLE internship_demands ADD COLUMN companyId INTEGER;");
      } catch (e) {}
      try {
        await db.execute("ALTER TABLE internship_demands ADD COLUMN domain TEXT;");
      } catch (e) {}
      try {
        await db.execute("ALTER TABLE internship_demands ADD COLUMN attachments TEXT;");
      } catch (e) {}
      try {
        await db.execute("ALTER TABLE internship_demands ADD COLUMN feedback TEXT;");
      } catch (e) {}
      try {
        await db.execute("ALTER TABLE internship_demands ADD COLUMN updatedAt TEXT;");
      } catch (e) {}
    }

    // v3 -> v4: further column additions and new table for notifications
    if (oldVersion < 4) {
      // Previously we added fcmToken; it's no longer used in the model, so we skip adding it on upgrades.
      try {
        await db.execute("CREATE TABLE IF NOT EXISTS in_app_notifications (id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, title TEXT, body TEXT, data TEXT, isRead INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL);");
      } catch (e) {}
    }

    // v4 -> v5: add parsed CVs table
    if (oldVersion < 5) {
      try {
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
      } catch (e) {}
    }
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
  }



  // ==================== CLOSE DATABASE ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
