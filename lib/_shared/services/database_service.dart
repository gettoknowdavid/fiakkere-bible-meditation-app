import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:fiakkere/_shared/models/objectbox.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Database implements Disposable {
  Database._(this._store);

  late final Store _store;

  Store get store => _store;

  static const _markerFilename = '.unzip_complete';
  static const _finalDirName = 'objectbox';
  static const _tempDirName = 'objectbox_temp_unzip';

  static Future<Database> create() async {
    final supportDir = await getApplicationSupportDirectory();
    final finalStoreDir = Directory(path.join(supportDir.path, _finalDirName));
    final markerFIle = File(path.join(finalStoreDir.path, _markerFilename));

    if (!await markerFIle.exists()) {
      await _unzipBundledStore(supportDir, finalStoreDir);
    }

    final store = await openStore(directory: finalStoreDir.path);
    return Database._(store);
  }

  static Future<void> _unzipBundledStore(
    Directory supportDirectory,
    Directory finalStoreDirectory,
  ) async {
    final tempDir = Directory(path.join(supportDirectory.path, _tempDirName));

    if (await tempDir.exists()) await tempDir.delete(recursive: true);
    await tempDir.create(recursive: true);

    final bytesData = await rootBundle.load('assets/bible_db.zip');
    final bytes = bytesData.buffer.asUint8List();

    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final outPath = path.join(tempDir.path, file.name);
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }

    await File(path.join(tempDir.path, _markerFilename)).create();

    if (await finalStoreDirectory.exists()) {
      await finalStoreDirectory.delete(recursive: true);
    }

    await tempDir.rename(finalStoreDirectory.path);
  }

  @override
  FutureOr<dynamic> onDispose() {
    _store.close();
  }
}
