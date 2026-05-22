import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('events_ticket.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDBFromSqlFile,
    );
  }

  // Hàm đọc file .sql từ assets và thực thi vào database
  Future _createDBFromSqlFile(Database db, int version) async {
    try {
      // 1. Đọc nội dung file SQL thành chuỗi chữ string
      String sqlScript = await rootBundle.loadString('assets/init_data.sql');

      // 2. Tách các câu lệnh dựa vào dấu chấm phẩy ;
      List<String> statements = sqlScript.split(';');

      // 3. Chạy từng câu lệnh SQL vào hệ thống
      for (String statement in statements) {
        if (statement.trim().isNotEmpty) {
          await db.execute(statement.trim());
        }
      }
    } catch (e) {
      print("Lỗi khi đọc file SQL: $e");
    }
  }

  Future<List<Map<String, dynamic>>> queryAllEvents() async {
    final db = await instance.database;
    return await db.query('events');
  }

  Future<int> insertTicket(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('tickets', row);
  }

  Future<List<Map<String, dynamic>>> queryAllTickets() async {
    final db = await instance.database;
    return await db.query('tickets');
  }
}