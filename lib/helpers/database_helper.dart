import 'package:onboarding_alarm_app/features/alarm/alarm_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'alarms.db';
  static const String _tableName = 'alarms';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY,
        scheduledAt TEXT NOT NULL,
        title TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertAlarm(AlarmModel alarm) async {
    final Database db = await database;
    await db.insert(
      _tableName,
      alarm.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AlarmModel>> getAlarms() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List<AlarmModel>.generate(maps.length, (int i) {
      return AlarmModel.fromJson(maps[i]);
    });
  }

  Future<void> deleteAlarm(int id) async {
    final Database db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
