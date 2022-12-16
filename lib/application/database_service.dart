import 'package:ebon_tracker/data/attachment.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/discount.dart';
import '../data/product.dart';

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

  // When the database is first created, create a table to store breeds
  // and a table to store dogs.
  Future<void> _onCreate(Database db, int version) async {
    // Run the CREATE {attachments} TABLE statement on the database.
    await db.execute(
      'CREATE TABLE receipts(id VARCHAR, timestamp TIMESTAMP, content BLOB, total REAL, PRIMARY KEY (id))',
    );

    await db.execute(
      'CREATE TABLE discounts(messageId VARCHAR, name VARCHAR, value REAL, FOREIGN KEY(messageId) REFERENCES receipts(id))',
    );

    await db.execute(
      'CREATE TABLE expenses(messageId VARCHAR, name VARCHAR, price REAL, quantity REAL, unit VARCHAR, discount REAL, total REAL, FOREIGN KEY(messageId) REFERENCES receipts(id))',
    );
  }

  // Define a function that inserts attachments into the database
  Future<void> insertExpense(String messageId, Product expense) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'expenses',
      expense.toMap(messageId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Define a function that inserts attachments into the database
  Future<void> insertExpenses(String messageId, List<Product> expenses) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    String values = expenses
        .map((e) =>
            "('${e.messageId}','${e.name}',${e.quantity},${e.price},${e.total()},${e.discount},'${e.unit}')")
        .join(",");

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.rawInsert(
        'INSERT INTO expenses(messageId, name, quantity, price, total, discount, unit) VALUES $values');
  }

  Future<List<Product>> expenses() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('expenses', orderBy: "name");
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> expensesByName(String name) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('expenses', where: 'name = ?', whereArgs: [name]);
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<List<Product>> expensesByMessageId(String messageId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db
        .query('expenses', where: 'messageId = ?', whereArgs: [messageId]);
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<void> insertDiscounts(
      String messageId, List<Discount> discounts) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    String values =
        discounts.map((d) => "('$messageId','${d.name}',${d.value})").join(",");

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.rawInsert(
        'INSERT INTO discounts(messageId, name, value) VALUES $values');
  }

  Future<List<Discount>> discounts(String messageId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db
        .query('discounts', where: 'messageId = ?', whereArgs: [messageId]);
    return maps.map((e) => Discount.fromMap(e)).toList();
  }

  // Define a function that inserts attachments into the database
  Future<void> insertAttachment(Attachment attachment) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'receipts',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  Future<void> updateAttachment(Attachment attachment) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Insert the Breed into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same breed is inserted twice.
    //
    // In this case, replace any previous data.
    await db.update('receipts', attachment.toMap(),
        where: 'id = ?', whereArgs: [attachment.id]);
  }

  // A method that retrieves all the attachments from the breeds table.
  Future<List<Attachment>> attachments() async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Query the table for all the attachments.
    final List<Map<String, dynamic>> maps =
        await db.query('receipts', orderBy: 'timestamp DESC');

    // Convert the List<Map<String, dynamic> into a List<Attachment>.
    return List.generate(
        maps.length, (index) => Attachment.fromMap(maps[index]));
  }

  Future<Attachment?> attachment(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('receipts', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Attachment.fromMap(maps[0]);
    } else {
      return null;
    }
  }

  // A method that deletes a breed data from the attachments table.
  Future<void> deleteAttachment(String id) async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Remove the Breed from the database.
    await db.delete(
      'receipts',
      // Use a `where` clause to delete a specific breed.
      where: 'id = ?',
      // Pass the Breed's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  // A method that deletes a breed data from the attachments table.
  Future<void> deleteAttachments() async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Remove the Breed from the database.
    await db.delete(
      'receipts',
    );
  }

  Future<void> deleteExpenses() async {
    // Get a reference to the database.
    final db = await _databaseService.database;

    // Remove the Breed from the database.
    await db.delete(
      'expenses',
    );
  }
}
