import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/asset.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'assets.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventory_number TEXT NOT NULL,
        name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        initial_cost REAL NOT NULL,
        salvage_value REAL DEFAULT 0,
        useful_life_months INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        location TEXT,
        responsible_person TEXT,
        status TEXT DEFAULT 'active',
        notes TEXT,
        department TEXT,
        cipher TEXT,
        serial_number TEXT,
        equipment_type TEXT,
        quantity INTEGER DEFAULT 1,
        unit TEXT,
        indicator TEXT,
        inactive_date TEXT,
        resume_date TEXT,
        status_date TEXT,
        card TEXT,
        is_deleted INTEGER DEFAULT 0,
        deleted_reason TEXT,
        deleted_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');
    // seed categories
    const cats = ['Здания и сооружения', 'Машины и оборудование',
      'Транспортные средства', 'Вычислительная техника',
      'Офисная мебель', 'Инструменты и приборы',
      'Производственный инвентарь', 'Прочие основные средства'];
    for (final c in cats) {
      await db.insert('categories', {'name': c});
    }
  }

  Future<List<Asset>> getAssets({String? search, String? card, String? status, bool? deleted, bool? zeroResidual}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (deleted == true) {
      where.add('is_deleted = 1');
    } else {
      where.add('is_deleted != 1');
    }
    if (search != null && search.isNotEmpty) {
      where.add('(inventory_number LIKE ? OR name LIKE ? OR location LIKE ? OR department LIKE ?)');
      final like = '%$search%';
      args.addAll([like, like, like, like]);
    }
    if (card != null && card.isNotEmpty) {
      where.add('card = ?');
      args.add(card);
    }
    if (status != null && status.isNotEmpty) {
      where.add('status = ?');
      args.add(status);
    }
    if (zeroResidual == true) {
      where.add('salvage_value <= 0');
    }
    final rows = await db.query('assets',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'inventory_number');
    return rows.map((r) => Asset.fromMap(r)).toList();
  }

  Future<void> insertAsset(Asset a) async {
    final db = await database;
    a.id = await db.insert('assets', a.toMap()..remove('id'));
  }

  Future<void> updateAsset(Asset a) async {
    final db = await database;
    await db.update('assets', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> softDeleteAsset(int id, String? reason) async {
    final db = await database;
    await db.update('assets', {
      'is_deleted': 1, 'deleted_reason': reason,
      'deleted_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restoreAsset(int id) async {
    final db = await database;
    await db.update('assets', {
      'is_deleted': 0, 'deleted_reason': null, 'deleted_at': null,
    }, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAssetPermanently(int id) async {
    final db = await database;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }
}