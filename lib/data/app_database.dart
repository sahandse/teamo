import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final base = await getDatabasesPath();
    final path = join(base, 'teamo.db');
    _database = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTasks(db);
        await _createProjects(db);
        await _createFollowups(db);
        await _createMeetings(db);
        await _createSprints(db);
        await _createWorkItems(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createProjects(db);
          await _createFollowups(db);
        }
        if (oldVersion < 3) {
          await _createMeetings(db);
        }
        if (oldVersion < 4) {
          await _createSprints(db);
        }
        if (oldVersion < 5) {
          await _createWorkItems(db);
        }
      },
    );
    return _database!;
  }

  static Future<void> _createTasks(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        project TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        assignee TEXT NOT NULL DEFAULT '',
        due_date TEXT,
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createProjects(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        owner TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'active',
        progress REAL NOT NULL DEFAULT 0,
        due_date TEXT,
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createFollowups(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS followups(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        context TEXT NOT NULL DEFAULT '',
        assignee TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'open',
        due_date TEXT,
        snoozed_until TEXT,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createMeetings(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meetings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        project TEXT NOT NULL DEFAULT '',
        attendees TEXT NOT NULL DEFAULT '',
        starts_at TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 30,
        agenda TEXT NOT NULL DEFAULT '',
        decisions TEXT NOT NULL DEFAULT '',
        action_items TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createSprints(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sprints(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        project TEXT NOT NULL DEFAULT '',
        goal TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'planned',
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        planned_points INTEGER NOT NULL DEFAULT 0,
        completed_points INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createWorkItems(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS work_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        project TEXT NOT NULL DEFAULT '',
        sprint_id INTEGER,
        type TEXT NOT NULL DEFAULT 'story',
        status TEXT NOT NULL DEFAULT 'backlog',
        story_points INTEGER NOT NULL DEFAULT 0,
        assignee TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY(sprint_id) REFERENCES sprints(id) ON DELETE SET NULL
      )
    ''');
  }
}
