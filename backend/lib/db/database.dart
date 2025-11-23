import 'package:sqlite_async/sqlite_async.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late final SqliteDatabase _db;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> init(String path) async {
    _db = SqliteDatabase(path: path);
    await _migrate();
  }

  SqliteDatabase get db => _db;

  Future<void> _migrate() async {
    final migrations = SqliteMigrations()
      ..add(
        SqliteMigration(1, (tx) async {
          await tx.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            name TEXT,
            created_at TEXT NOT NULL
          );
        ''');

          await tx.execute('''
          CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            api_key TEXT UNIQUE NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users (id)
          );
        ''');

          await tx.execute('''
          CREATE TABLE IF NOT EXISTS logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id TEXT NOT NULL,
            type TEXT NOT NULL,
            level TEXT NOT NULL,
            message TEXT,
            timestamp TEXT NOT NULL,
            stack_trace TEXT,
            metadata TEXT,
            device TEXT,
            received_at TEXT NOT NULL,
            user_id TEXT,
            user_name TEXT,
            user_email TEXT,
            session_id TEXT,
            FOREIGN KEY (project_id) REFERENCES projects (id)
          );
        ''');

          // Create indexes for better performance
          await tx.execute(
            'CREATE INDEX IF NOT EXISTS idx_logs_project_id ON logs(project_id);',
          );
          await tx.execute(
            'CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);',
          );
          await tx.execute(
            'CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);',
          );
          await tx.execute(
            'CREATE INDEX IF NOT EXISTS idx_logs_session_id ON logs(session_id);',
          );
        }),
      );

    await migrations.migrate(_db);
  }
}
