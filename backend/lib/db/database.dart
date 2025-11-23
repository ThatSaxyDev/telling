import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late final Database _db;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  void init(String path) {
    _db = sqlite3.open(path);
    _createTables();
  }

  Database get db => _db;

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT,
        created_at TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        api_key TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      );
    ''');

    _db.execute('''
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
    _db.execute('CREATE INDEX IF NOT EXISTS idx_logs_project_id ON logs(project_id);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs(user_id);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_logs_session_id ON logs(session_id);');
  }
}
