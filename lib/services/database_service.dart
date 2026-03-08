import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pyquest.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Create UserProgress table
    await db.execute('''
      CREATE TABLE UserProgress (
          id INTEGER PRIMARY KEY DEFAULT 1,
          total_xp INTEGER DEFAULT 0,
          current_level INTEGER DEFAULT 1,
          streak_count INTEGER DEFAULT 0,
          last_login_date TEXT,
          character_name TEXT DEFAULT 'Data Knight',
          current_tier_id INTEGER DEFAULT 1
      )
    ''');

    // Create LessonStatus table
    await db.execute('''
      CREATE TABLE LessonStatus (
          lesson_id TEXT PRIMARY KEY,
          is_completed INTEGER DEFAULT 0,
          quiz_score REAL DEFAULT 0.0,
          is_boss_defeated INTEGER DEFAULT 0,
          mastered INTEGER DEFAULT 0
      )
    ''');

    // Create Inventory table
    await db.execute('''
      CREATE TABLE Inventory (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id TEXT UNIQUE,
          item_name TEXT NOT NULL,
          item_type TEXT,
          unlocked_at TEXT
      )
    ''');

    // Initialize UserProgress
    await db.insert('UserProgress', {
      'id': 1,
      'total_xp': 0,
      'current_level': 1,
      'streak_count': 0,
      'last_login_date': DateTime.now().toIso8601String(),
    });
  }

  // --- UserProgress Methods ---

  Future<Map<String, dynamic>> getUserProgress() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('UserProgress', where: 'id = ?', whereArgs: [1]);
    return maps.isNotEmpty ? maps.first : {};
  }

  Future<void> updateXP(int newXP, int newLevel) async {
    final db = await database;
    await db.update(
      'UserProgress',
      {'total_xp': newXP, 'current_level': newLevel},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // --- LessonStatus Methods ---

  Future<List<Map<String, dynamic>>> getAllLessonStatus() async {
    final db = await database;
    return await db.query('LessonStatus');
  }

  Future<void> saveLessonStatus(String lessonId, bool isCompleted, double score) async {
    final db = await database;
    await db.insert(
      'LessonStatus',
      {
        'lesson_id': lessonId,
        'is_completed': isCompleted ? 1 : 0,
        'quiz_score': score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Inventory Methods ---

  Future<List<Map<String, dynamic>>> getInventory() async {
    final db = await database;
    return await db.query('Inventory');
  }

  Future<void> unlockItem(String itemId, String itemName, String itemType) async {
    final db = await database;
    await db.insert(
      'Inventory',
      {
        'item_id': itemId,
        'item_name': itemName,
        'item_type': itemType,
        'unlocked_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
