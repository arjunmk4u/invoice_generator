import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('invoices.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Added clientEmail, clientPhone columns
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Invoices table
    await db.execute('''
      CREATE TABLE invoices (
        id $idType,
        invoiceNumber $textType,
        clientName $textType,
        clientEmail $textTypeNullable,
        clientPhone $textTypeNullable,
        issueDate $textType,
        status $textType,
        grandTotal $realType,
        notes $textTypeNullable,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id $idType,
        invoiceId $intType,
        itemName $textType,
        quantity $realType,
        pricePerUnit $realType,
        total $realType,
        FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // User profile table
    await db.execute('''
      CREATE TABLE user_profile (
        id $idType,
        userName $textType,
        companyName $textTypeNullable,
        companyAddress $textTypeNullable,
        companyPhone $textTypeNullable,
        companyEmail $textTypeNullable,
        gstNumber $textTypeNullable
      )
    ''');

    // Insert default user profile
    await db.insert('user_profile', {
      'userName': 'user',
      'companyName': '',
      'companyAddress': '',
      'companyPhone': '',
      'companyEmail': '',
      'gstNumber': '',
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add user_profile table for existing databases
      await db.execute('''
        CREATE TABLE user_profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userName TEXT NOT NULL,
          companyName TEXT,
          companyAddress TEXT,
          companyPhone TEXT,
          companyEmail TEXT,
          gstNumber TEXT
        )
      ''');

      await db.insert('user_profile', {
        'userName': 'user',
        'companyName': '',
        'companyAddress': '',
        'companyPhone': '',
        'companyEmail': '',
        'gstNumber': '',
      });
    }

    if (oldVersion < 3) {
      // Add clientEmail and clientPhone to invoices table
      await db.execute('ALTER TABLE invoices ADD COLUMN clientEmail TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN clientPhone TEXT');
    }
  }

  // Invoice operations
  Future<int> createInvoice(Map<String, dynamic> invoice) async {
    final db = await instance.database;
    return await db.insert('invoices', invoice);
  }

  Future<Map<String, dynamic>?> readInvoice(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> readAllInvoices() async {
    final db = await instance.database;
    return await db.query('invoices', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getRecentInvoices({int limit = 5}) async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getInvoicesByStatus(String status) async {
    final db = await instance.database;
    return await db.query(
      'invoices',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateInvoice(int id, Map<String, dynamic> invoice) async {
    final db = await instance.database;
    return await db.update(
      'invoices',
      invoice,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Invoice items operations
  Future<int> createInvoiceItem(Map<String, dynamic> item) async {
    final db = await instance.database;
    return await db.insert('invoice_items', item);
  }

  Future<List<Map<String, dynamic>>> getInvoiceItems(int invoiceId) async {
    final db = await instance.database;
    return await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<int> deleteInvoiceItems(int invoiceId) async {
    final db = await instance.database;
    return await db.delete(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<int> getInvoiceCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalRevenue() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(grandTotal) as total FROM invoices WHERE status = ?',
      ['paid'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // User profile operations
  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  Future<int> updateUserProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    return await db.update(
      'user_profile',
      profile,
      where: 'id = ?',
      whereArgs: [profile['id']],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
