import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:fiakkere/_shared/models/objectbox.g.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class Database {
  Database._(this.store);

  final Store store;

  static Future<Database> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory('${docsDir.path}/objectbox');

    if (!storeDir.existsSync()) await _unzipBundledStore(storeDir);

    final store = await openStore(directory: storeDir.path);
    return Database._(store);
  }

  static Future<void> _unzipBundledStore(Directory target) async {
    final bytes = await rootBundle.load('assets/bible_db.zip');
    final archive = ZipDecoder().decodeBytes(bytes.buffer.asUint8List());
    await target.create(recursive: true);

    for (final file in archive) {
      final outPath = '${target.path}/${file.name}';
      if (file.isFile) {
        final outFile = File(outPath)..createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }
  }
}
