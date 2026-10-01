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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
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
      },
    );
    return _database!;
  }
}
