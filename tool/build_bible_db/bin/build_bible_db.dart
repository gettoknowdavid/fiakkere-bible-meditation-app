import 'dart:convert';
import 'dart:io';
import 'package:bible_models/bible_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  final dbPath = File('build_output/bible_db.sqlite').absolute.path;
  final dbFile = File(dbPath);
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
  }

  final db = await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE verses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              reference TEXT,
              universalKey TEXT,
              book INTEGER,
              chapter INTEGER,
              verse INTEGER,
              text TEXT,
              translation TEXT
            )
          ''');
        // Add indices for faster lookup
        await db.execute(
          'CREATE INDEX idx_verses_book_chapter ON verses(book, chapter)',
        );
        await db.execute(
          'CREATE INDEX idx_verses_universalKey ON verses(universalKey)',
        );
        await db.execute('CREATE INDEX idx_verses_text ON verses(text)');

        await db.execute('''
            CREATE TABLE cross_references(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sourceVerseId INTEGER,
              relatedVerseId INTEGER,
              weight INTEGER,
              FOREIGN KEY(sourceVerseId) REFERENCES verses(id),
              FOREIGN KEY(relatedVerseId) REFERENCES verses(id)
            )
          ''');
        await db.execute(
          'CREATE INDEX idx_crossrefs_source ON cross_references(sourceVerseId)',
        );
      },
    ),
  );

  print('Reading json source assets...');
  final String webJsonContent = File('source_data/web.json').readAsStringSync();
  final Map<String, dynamic> webDataMap = jsonDecode(webJsonContent);
  final List<dynamic> rawVerses = webDataMap['verses'];

  final String refsJsonContent = File(
    'source_data/cross_references.json',
  ).readAsStringSync();
  final List<dynamic> rawRefs = jsonDecode(refsJsonContent);

  print('Parsing verse entities...');
  final List<Verse> verseEntities = rawVerses
      .map((j) => Verse.fromJson(j as Map<String, dynamic>))
      .toList();

  final verseIdLookup = <String, int>{};

  print('Seeding verses...');
  await db.transaction((txn) async {
    final batch = txn.batch();
    for (final verse in verseEntities) {
      batch.insert('verses', verse.toMap());
    }
    final results = await batch.commit();

    // Map generated SQLite IDs to their universalKeys
    for (int i = 0; i < verseEntities.length; i++) {
      verseIdLookup[verseEntities[i].universalKey] = results[i] as int;
    }
  });

  print('Building relational cross-reference objects...');
  int skipped = 0;

  await db.transaction((txn) async {
    final batch = txn.batch();
    for (final refJson in rawRefs) {
      final mapData = refJson as Map<String, dynamic>;
      final sKey = mapData['sourceKey'] as String;
      final rKey = mapData['relatedKey'] as String;

      final sourceId = verseIdLookup[sKey];
      final relatedId = verseIdLookup[rKey];

      if (sourceId != null && relatedId != null) {
        batch.insert('cross_references', {
          'sourceVerseId': sourceId,
          'relatedVerseId': relatedId,
          'weight': mapData['weight'] as int,
        });
      } else {
        skipped++;
      }
    }
    await batch.commit(noResult: true);
  });

  final verseResult = await db.rawQuery('SELECT COUNT(*) FROM verses');
  final verseCount = verseResult.first.values.first as int;

  final refResult = await db.rawQuery('SELECT COUNT(*) FROM cross_references');
  final refCount = refResult.first.values.first as int;

  print('Success!');
  print('Imported $verseCount relational verses.');
  print('Imported $refCount native relation references.');
  print('Skipped $skipped unresolved tracking mappings.');

  await db.close();
}
