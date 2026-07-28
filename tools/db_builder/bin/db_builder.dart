import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:models/models.dart';
import 'package:path/path.dart' as p;

// OSIS book abbreviation to book integer mapping (OpenBible standard)
final Map<String, int> osisBooks = {
  'Gen': 1,
  'Exod': 2,
  'Lev': 3,
  'Num': 4,
  'Deut': 5,
  'Josh': 6,
  'Judg': 7,
  'Ruth': 8,
  '1Sam': 9,
  '2Sam': 10,
  '1Kgs': 11,
  '2Kgs': 12,
  '1Chr': 13,
  '2Chr': 14,
  'Ezra': 15,
  'Neh': 16,
  'Esth': 17,
  'Job': 18,
  'Ps': 19,
  'Prov': 20,
  'Eccl': 21,
  'Song': 22,
  'Isa': 23,
  'Jer': 24,
  'Lam': 25,
  'Ezek': 26,
  'Dan': 27,
  'Hos': 28,
  'Joel': 29,
  'Amos': 30,
  'Obad': 31,
  'Jonah': 32,
  'Mic': 33,
  'Nah': 34,
  'Hab': 35,
  'Zeph': 36,
  'Hag': 37,
  'Zech': 38,
  'Mal': 39,
  'Matt': 40,
  'Mark': 41,
  'Luke': 42,
  'John': 43,
  'Acts': 44,
  'Rom': 45,
  '1Cor': 46,
  '2Cor': 47,
  'Gal': 48,
  'Eph': 49,
  'Phil': 50,
  'Col': 51,
  '1Thess': 52,
  '2Thess': 53,
  '1Tim': 54,
  '2Tim': 55,
  'Titus': 56,
  'Phlm': 57,
  'Heb': 58,
  'Jas': 59,
  '1Pet': 60,
  '2Pet': 61,
  '1John': 62,
  '2John': 63,
  '3John': 64,
  'Jude': 65,
  'Rev': 66,
};

void main() async {
  final currentDir = Directory.current.path;
  final dbPath = p.join(currentDir, 'build_output');
  final zipOutputPath = p.join(
    currentDir,
    '..',
    '..',
    'assets',
    'bible_db.zip',
  );

  // Clean previous DB build
  final outDir = Directory(dbPath);
  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }

  // 1. Create the ObjectBox Store
  print('Initializing ObjectBox Store...');
  final store = Store(getObjectBoxModel(), directory: dbPath);
  final metaBox = store.box<Metadata>();
  final verseBox = store.box<Verse>();
  final crossRefBox = store.box<CrossReference>();

  // 2. Parse web.json and seed Verses & Metadata
  print('Parsing WEB Bible JSON...');
  final webJsonFile = File(p.join(currentDir, 'source_data', 'web.json'));
  final webData = jsonDecode(await webJsonFile.readAsString());

  final metaData = webData['metadata'];
  final metadataEntity = Metadata(
    name: metaData['name'],
    shortname: metaData['shortname'],
    module: metaData['module'],
    year: metaData['year'].toString(),
    publisher: metaData['publisher'],
    owner: metaData['owner'],
    description: metaData['description'],
    lang: metaData['lang'],
    langShort: metaData['lang_short'],
    copyrightStatement: metaData['copyright_statement'],
  );

  metaBox.put(metadataEntity);

  final List<dynamic> versesJson = webData['verses'];
  List<Verse> versesToInsert = [];

  // Fast lookup map to resolve CrossReferences locally without DB queries
  Map<String, Verse> verseMap = {};

  for (var v in versesJson) {
    String bookName = v['book_name'];
    int bookNum = v['book'];
    int chapter = v['chapter'];
    int verseNum = v['verse'];

    final verseEntity = Verse(
      reference: '$bookName $chapter:$verseNum',
      book: bookNum,
      chapter: chapter,
      verse: verseNum,
      text: v['text'],
    );

    verseEntity.metadata.target = metadataEntity;
    versesToInsert.add(verseEntity);
  }

  print('Inserting ${versesToInsert.length} verses into ObjectBox...');
  verseBox.putMany(versesToInsert);

  // Populate the lookup map with the inserted verses (so they have valid ObjectBox IDs)
  for (var v in versesToInsert) {
    verseMap['${v.book}.${v.chapter}.${v.verse}'] = v;
  }

  // 3. Parse cross_references.txt and seed CrossReferences
  print('Parsing Cross References...');
  final tskFile = File(
    p.join(currentDir, 'source_data', 'cross_references.txt'),
  );
  final lines = await tskFile.readAsLines();

  List<CrossReference> crossRefsToInsert = [];

  for (var line in lines) {
    if (line.trim().isEmpty || line.startsWith('From Verse')) continue;

    final parts = line.split('\t');
    if (parts.length < 3) continue;

    final sourceKey = parts[0].trim(); // e.g., Gen.1.1
    final targetRef = parts[1].trim(); // e.g., Col.1.16-Col.1.17
    final weight = int.tryParse(parts[2].trim()) ?? 0;

    final sourceVerse = _resolveVerseMap(sourceKey, verseMap);
    if (sourceVerse == null) continue;

    // Handle single verses OR ranges (e.g., Book.Ch.V1-Book.Ch.V2)
    final targets = targetRef.split('-');

    for (var target in targets) {
      final relatedVerse = _resolveVerseMap(target, verseMap);

      if (relatedVerse != null) {
        final cr = CrossReference(weight: weight);
        cr.sourceVerse.target = sourceVerse;
        cr.relatedVerse.target = relatedVerse;
        crossRefsToInsert.add(cr);
      }
    }
  }

  print('Inserting ${crossRefsToInsert.length} cross references...');
  crossRefBox.putMany(crossRefsToInsert);

  // Close store properly before zipping
  store.close();
  print('Database generated successfully.');

  // 4. Zip the ObjectBox directory for bundling
  final assetPath = p.canonicalize(p.join(currentDir, '..', '..', 'assets'));
  final assetDir = Directory(assetPath);
  if (!assetDir.existsSync()) {
    assetDir.createSync(recursive: true);
  }

  final zipFile = File(zipOutputPath);

  // Remove old zip file to prevent Windows overwrite permission conflicts
  if (zipFile.existsSync()) {
    try {
      zipFile.deleteSync();
    } catch (e) {
      print(
        'Warning: Could not delete existing zip. Make sure Flutter/emulator is stopped: $e',
      );
    }
  }

  print('Zipping database to $zipOutputPath...');

  // Use zipDirectory with await so it finishes completely before reading file size
  final encoder = ZipFileEncoder();
  await encoder.zipDirectory(Directory(dbPath), filename: zipOutputPath);

  print(
    'Bundled zipped DB created! Size: ${(zipFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
  );
}

/// Helper method to safely map OSIS reference formats to our fast in-memory map
Verse? _resolveVerseMap(String osisRef, Map<String, Verse> map) {
  final parts = osisRef.split('.');
  if (parts.length != 3) return null;

  final osisBookCode = parts[0];
  final chapter = parts[1];
  final verseNum = parts[2];

  final bookNum = osisBooks[osisBookCode];
  if (bookNum == null) return null;

  return map['$bookNum.$chapter.$verseNum'];
}
