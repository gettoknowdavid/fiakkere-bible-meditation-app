import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseService implements Disposable {
  // Private constructor ensures the class can only be instantiated
  // via the async create() factory method.
  DatabaseService._(this._db);

  final sqflite.Database _db;

  /// Expose the underlying sqflite database instance for queries
  sqflite.Database get db => _db;

  static const _dbName = 'bible_db.sqlite';

  /// Asynchronously initializes and returns a fully prepared DatabaseService.
  static Future<DatabaseService> create() async {
    final dbDirPath = await sqflite.getDatabasesPath();
    final dbPath = path.join(dbDirPath, _dbName);

    // Check if the database has already been copied to the device's native storage
    final exists = await sqflite.databaseExists(dbPath);

    if (!exists) {
      // Ensure the parent directory exists before attempting to write
      try {
        await Directory(path.dirname(dbPath)).create(recursive: true);
      } catch (_) {}

      // Load the pre-seeded SQLite file bundled in the Flutter assets
      final ByteData data = await rootBundle.load('assets/$_dbName');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write the bytes to the device's native database directory
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    // Open the connection to the local database file
    final database = await sqflite.openDatabase(dbPath);

    return DatabaseService._(database);
  }

  @override
  FutureOr<dynamic> onDispose() {
    // Safely close the database connection when the service is disposed
    _db.close();
  }
}
