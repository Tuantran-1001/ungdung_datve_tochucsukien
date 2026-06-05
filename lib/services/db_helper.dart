import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  // Bộ nhớ đệm lưu vé & giao dịch trong RAM dành riêng cho nền tảng Web do sqflite không hỗ trợ trực tiếp trên web
  static final List<Map<String, dynamic>> _webTicketsMemory = [];
  static final List<Map<String, dynamic>> _webTransactionsMemory = [];

  DbHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database;
    _database = await _initDB('event_pro_v4.db'); // Đổi tên file db để cập nhật cấu trúc mới
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Bảng lưu danh sách sự kiện
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT,
        category TEXT,
        date TEXT,
        location TEXT,
        description TEXT,
        imageUrl TEXT,
        price REAL,
        totalSeats INTEGER,
        availableSeats INTEGER
      )
    ''');

    // 2. Bảng lưu vé điện tử đã đặt
    await db.execute('''
      CREATE TABLE tickets (
        id TEXT PRIMARY KEY,
        userId TEXT,
        eventId TEXT,
        eventTitle TEXT,
        eventDate TEXT,
        eventLocation TEXT,
        seatNumber TEXT,
        status TEXT, -- 'Chưa sử dụng' hoặc 'Đã check-in'
        bookingTime TEXT
      )
    ''');

    // 3. Bảng lưu lịch sử giao dịch & hóa đơn
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT,
        eventTitle TEXT,
        bookingTime TEXT,
        paymentMethod TEXT,
        amount REAL,
        seatNumber TEXT,
        ticketCount INTEGER
      )
    ''');

    // Chèn dữ liệu mẫu
    await _insertMockEvents(db);
  }

  Future<void> _insertMockEvents(Database db) async {
    await db.rawInsert('''
      INSERT INTO events VALUES(
        'e1', 'Liveshow Âm Nhạc: Thanh Âm Mùa Hè', 'Âm nhạc', '2026-06-15 19:30', 
        'Nhà thi đấu Phú Thọ, TP.HCM', 'Đêm nhạc hội quy tụ những ngôi sao hàng đầu với hệ thống âm thanh ánh sáng chuẩn quốc tế.',
        'https://images.unsplash.com/photo-1506157786151-b8491531f063', 500000, 100, 85
      )
    ''');

    await db.rawInsert('''
      INSERT INTO events VALUES(
        'e2', 'Giải Chạy Marathon Quốc Tế 2026', 'Thể thao', '2026-07-20 05:00', 
        'Công viên Sala, Quận 2, TP.HCM', 'Thử thách bản thân với các cự ly 5km, 10km và 21km trên cung đường xanh mát.',
        'https://images.unsplash.com/photo-1502224562085-639556652f33', 250000, 500, 420
      )
    ''');

    await db.rawInsert('''
      INSERT INTO events VALUES(
        'e3', 'Workshop: Lập trình Flutter từ số 0', 'Workshop', '2026-05-30 09:00', 
        'DREAMPLEX Nguyễn Trung Ngạn, Q.1', 'Buổi chia sẻ chuyên sâu giúp bạn làm chủ Flutter và xây dựng ứng dụng đa nền tảng.',
        'https://images.unsplash.com/photo-1515187029135-18ee286d815b', 120000, 50, 12
      )
    ''');
  }

  // --- Các hàm truy vấn dữ liệu ---
  Future<List<Map<String, dynamic>>> queryAllEvents() async {
    if (kIsWeb) return [];
    final db = await instance.database;
    if (db == null) return [];
    return await db.query('events');
  }

  Future<List<Map<String, dynamic>>> queryAllTickets(String? userId) async {
    if (kIsWeb) {
      if (userId == null) return [];
      return _webTicketsMemory.where((t) => t['userId'] == userId).toList();
    }
    final db = await instance.database;
    if (db == null) return [];
    if (userId == null) return [];
    return await db.query(
      'tickets',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> insertTicket(Map<String, dynamic> data) async {
    if (kIsWeb) {
      _webTicketsMemory.add(data);
      return;
    }
    final db = await instance.database;
    if (db != null) {
      await db.insert('tickets', data);
    }
  }

  // Kiểm soát vé tại cửa: Cập nhật trạng thái vé khi quét mã QR thành công
  Future<int> checkInTicket(String ticketId) async {
    if (kIsWeb) {
      final index = _webTicketsMemory.indexWhere((t) => t['id'] == ticketId);
      if (index != -1) {
        final ticket = Map<String, dynamic>.from(_webTicketsMemory[index]);
        ticket['status'] = 'Đã check-in';
        _webTicketsMemory[index] = ticket;
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    if (db == null) return 0;
    return await db.update(
        'tickets',
        {'status': 'Đã check-in'},
        where: 'id = ?',
        whereArgs: [ticketId]
    );
  }

  // --- Các hàm nghiệp vụ Lịch sử Giao dịch ---
  Future<void> insertTransaction(Map<String, dynamic> data) async {
    if (kIsWeb) {
      _webTransactionsMemory.add(data);
      return;
    }
    final db = await instance.database;
    if (db != null) {
      await db.insert('transactions', data);
    }
  }

  Future<List<Map<String, dynamic>>> queryAllTransactions(String? userId) async {
    if (kIsWeb) {
      if (userId == null) return [];
      return _webTransactionsMemory.where((t) => t['userId'] == userId).toList();
    }
    final db = await instance.database;
    if (db == null) return [];
    if (userId == null) return [];
    return await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'bookingTime DESC',
    );
  }
}