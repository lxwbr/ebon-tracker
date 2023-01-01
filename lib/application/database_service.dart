import 'package:ebon_tracker/data/attachment.dart';
import 'package:ebon_tracker/data/category.dart';
import 'package:ebon_tracker/data/product.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/discount.dart';
import '../data/expense.dart';
import '../data/receipt.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();

  // only have a single app-wide reference to the database
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the DB first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    final path = join(databasePath, ' .db');

    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    return await openDatabase(
      path,
      onCreate: _onCreate,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE receipts('
        'id VARCHAR PRIMARY KEY,'
        'timestamp TIMESTAMP,'
        'content BLOB,'
        'total REAL'
        ')');

    await db.execute('CREATE TABLE discounts('
        'messageId VARCHAR,'
        'name VARCHAR,'
        'value REAL,'
        'FOREIGN KEY(messageId) REFERENCES receipts(id)'
        ')');

    await db.execute('CREATE TABLE expenses('
        'messageId VARCHAR,'
        'name VARCHAR,'
        'price REAL,'
        'quantity REAL,'
        'unit VARCHAR,'
        'discount REAL,'
        'total REAL,'
        'category INTEGER,'
        'FOREIGN KEY(messageId) REFERENCES receipts(id),'
        'FOREIGN KEY(name) REFERENCES products(name)'
        ')');

    await db.execute('CREATE TABLE products('
        'name VARCHAR PRIMARY KEY,'
        'category INTEGER,'
        'FOREIGN KEY(category) REFERENCES categories(id)'
        ')');

    await db.execute('CREATE TABLE categories('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'name VARCHAR,'
        'parentId INTEGER,'
        'FOREIGN KEY(parentId) REFERENCES categories(id)'
        ')');
  }

  static _purge(String table) async {
    final db = await DatabaseService._databaseService.database;
    await db.delete(table);
  }
}

extension DiscountsDb on DatabaseService {
  static Future<void> insert(Iterable<Discount> discounts) async {
    if (discounts.isNotEmpty) {
      final db = await DatabaseService._databaseService.database;
      String values = discounts
          .map((d) => "('${d.messageId}','${d.name}',${d.value})")
          .join(",");
      await db.rawInsert(
          'INSERT INTO discounts(messageId, name, value) VALUES $values');
    }
  }

  static Future<List<Discount>> getByMessageId(String messageId) async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps = await db
        .query('discounts', where: 'messageId = ?', whereArgs: [messageId]);
    return maps.map((e) => Discount.fromMap(e)).toList();
  }

  static Future<void> purge() async {
    final db = await DatabaseService._databaseService.database;
    await db.delete(
      'discounts',
    );
  }
}

extension ExpensesDb on DatabaseService {
  static const String _tableName = 'expenses';

  static Future<void> purge() async {
    final db = await DatabaseService._databaseService.database;
    await db.delete(
      _tableName,
    );
  }

  static Future<void> insert(Iterable<Expense> expenses) async {
    if (expenses.isNotEmpty) {
      final db = await DatabaseService._databaseService.database;
      String values = expenses
          .map((e) =>
              "('${e.messageId}','${e.name}',${e.quantity},${e.price},${e.total()},${e.discount},'${e.unit.name}')")
          .join(",");
      await db.rawInsert(
          'INSERT INTO expenses(messageId, name, quantity, price, total, discount, unit) VALUES $values');
    }
  }

  static Future<List<Expense>> all() async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(_tableName, orderBy: "name");
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  static Future<List<Expense>> getByName(String name) async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(_tableName, where: 'name = ?', whereArgs: [name]);
    return maps.map((e) => Expense.fromMap(e)).toList();
  }

  static Future<Iterable<Expense>> between(DateTime from, DateTime to) async {
    final db = await DatabaseService._databaseService.database;
    String query = "SELECT receipts.timestamp AS timestamp, "
        "expenses.messageId AS messageId, "
        "expenses.name AS name, "
        "expenses.quantity AS quantity, "
        "expenses.price AS price, "
        "expenses.total AS total, "
        "expenses.discount AS discount, "
        "expenses.unit AS unit, "
        "categories.id AS categoryId, "
        "categories.name AS categoryName "
        "FROM receipts "
        "JOIN expenses ON receipts.id = expenses.messageId "
        "JOIN products ON expenses.name = products.name "
        "LEFT OUTER JOIN categories ON categories.id = products.category "
        "WHERE receipts.timestamp BETWEEN ${(from.millisecondsSinceEpoch / 1000).toStringAsFixed(0)} AND ${(to.millisecondsSinceEpoch / 1000).toStringAsFixed(0)}";

    print(query);
    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return maps.map((e) => Expense.fromMap(e));
  }

  static Future<List<Expense>> getByMessageId(String messageId) async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.rawQuery("SELECT expenses.name AS name, "
            "expenses.price AS price, "
            "expenses.quantity AS quantity, "
            "expenses.unit AS unit, "
            "expenses.discount AS discount, "
            "expenses.messageId AS messageId, "
            "categories.id AS categoryId, "
            "categories.name AS categoryName "
            "FROM expenses "
            "JOIN products ON expenses.name = products.name "
            "LEFT OUTER JOIN categories ON categories.id = products.category "
            "WHERE messageId = '$messageId'");
    return maps.map((e) => Expense.fromMap(e)).toList();
  }
}

extension ReceiptsDb on DatabaseService {
  static Future<Receipt?> get(String id) async {
    Attachment? attachment = await AttachmentsDb.get(id);
    if (attachment != null) {
      List<Expense> expenses = await ExpensesDb.getByMessageId(id);
      List<Discount> discounts = await DiscountsDb.getByMessageId(id);
      return Receipt(
          attachment: attachment, expenses: expenses, discounts: discounts);
    } else {
      return null;
    }
  }
}

extension AttachmentsDb on DatabaseService {
  static Future<List<Attachment>> all() async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('receipts', orderBy: 'timestamp DESC');
    return List.generate(
        maps.length, (index) => Attachment.fromMap(maps[index]));
  }

  static Future<Attachment?> get(String id) async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('receipts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Attachment.fromMap(maps.first);
    } else {
      return null;
    }
  }

  static Future<void> insert(Iterable<Attachment> attachments) async {
    if (attachments.isNotEmpty) {
      final db = await DatabaseService._databaseService.database;
      String values = attachments
          .map((a) => "('${a.id}',${a.timestamp},'${a.content}','${a.total}')")
          .join(",");
      await db.rawInsert(
          'INSERT INTO receipts (id, timestamp, content, total) VALUES $values');
    }
  }

  static Future<void> delete(String id) async {
    final db = await DatabaseService._databaseService.database;
    await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> purge() async {
    return DatabaseService._purge('receipts');
  }
}

extension ProductsDb on DatabaseService {
  static const String _tableName = 'products';

  static Future<List<Product>> all() async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(_tableName, orderBy: 'name ASC');
    return List.generate(maps.length, (index) => Product.fromMap(maps[index]));
  }

  static Future<void> insert(Iterable<Product> products) async {
    if (products.isNotEmpty) {
      final db = await DatabaseService._databaseService.database;
      String values =
          products.map((d) => "('${d.name}',${d.category})").join(",");
      await db.rawInsert(
          'INSERT OR IGNORE INTO products(name, category) VALUES $values');
    }
  }

  static Future<void> update(Product product) async {
    final db = await DatabaseService._databaseService.database;
    await db.update(_tableName, product.toMap(),
        where: 'name = ?', whereArgs: [product.name]);
  }

  static Future<void> purge() async {
    return DatabaseService._purge(_tableName);
  }
}

extension CategoriesDb on DatabaseService {
  static const String _tableName = 'categories';

  static Future<List<Category>> all() async {
    final db = await DatabaseService._databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query(_tableName, orderBy: 'id ASC');
    return List.generate(maps.length, (index) => Category.fromMap(maps[index]));
  }

  static Future<void> insert(String name, int? parent) async {
    final db = await DatabaseService._databaseService.database;
    db.insert(_tableName, {"name": name, "parentId": parent});
  }

  static Future<void> update(Category category) async {
    final db = await DatabaseService._databaseService.database;
    db.update(
        _tableName, {"name": category.name, "parentId": category.parentId},
        where: "id = ?", whereArgs: [category.id]);
  }

  static Future<void> purge() async {
    return DatabaseService._purge(_tableName);
  }
}
