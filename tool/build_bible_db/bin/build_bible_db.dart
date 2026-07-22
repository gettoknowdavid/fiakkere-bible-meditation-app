import 'dart:io';

import 'package:build_bible_db/models/cross_reference.dart';
import 'package:build_bible_db/models/verse.dart';
import 'package:build_bible_db/objectbox.g.dart';
import 'package:xml/xml.dart';

Future<void> main() async {
  final store = openStore(directory: 'build_output/objectbox');
  final verseBox = store.box<Verse>();
  final crossRefBox = store.box<CrossReference>();

  final xml = File('source_data/eng-web/web_usfx.xml').readAsStringSync();
  final rawVerses = parseUsfx(xml);
  final verseIdLookup = <String, int>{};

  for (final rv in rawVerses) {
    final bookNumber = usfxBookIdToNumber[rv.bookId];
    if (bookNumber != null) {
      final verse = Verse()
        ..book = bookNumber
        ..chapter = rv.chapter
        ..verse = rv.verseNumber
        ..text = rv.text
        ..translation = 'WEB'
        ..reference = _formatReference(bookNumber, rv.chapter, rv.verseNumber);
      final id = verseBox.put(verse);
      verseIdLookup['$bookNumber:${rv.chapter}:${rv.verseNumber}'] = id;
    }
  }

  final combinedSql = loadCombinedCrossRefSql('source_data/cross_refs');
  final rawRefs = parseCrossRefSql(combinedSql);

  int skipped = 0;
  for (final ref in rawRefs) {
    final fromBookNum = fullBookNameToNumber[ref.fromBook];
    final toBookNum = fullBookNameToNumber[ref.toBook];
    final fromKey = '$fromBookNum:${ref.fromChapter}:${ref.fromVerse}';
    final sourceId = verseIdLookup[fromKey];
    if (sourceId == null) {
      skipped++;
      continue;
    }

    for (var v = ref.toVerseStart; v <= ref.toVerseEnd; v++) {
      final toKey = '$toBookNum:${ref.toChapter}:$v';
      final relatedId = verseIdLookup[toKey];
      if (relatedId == null) {
        skipped++;
        continue;
      }

      final crossRef = CrossReference()..weight = ref.votes;
      crossRef.sourceVerse.targetId = sourceId;
      crossRef.relatedVerse.targetId = relatedId;
      crossRefBox.put(crossRef);
    }
  }

  print(
    'Imported ${verseBox.count()} verses, ${crossRefBox.count()} cross-references.',
  );
  print(
    'Skipped $skipped unresolved cross-reference rows (review before shipping).',
  );

  store.close();
}

class RawCrossRef {
  RawCrossRef({
    required this.fromBook,
    required this.fromChapter,
    required this.fromVerse,
    required this.toBook,
    required this.toChapter,
    required this.toVerseStart,
    required this.toVerseEnd,
    required this.votes,
  });

  final String fromBook;
  final int fromChapter;
  final int fromVerse;
  final String toBook;
  final int toChapter;
  final int toVerseStart;
  final int toVerseEnd;
  final int votes;
}

class RawVerse {
  const RawVerse(this.bookId, this.chapter, this.verseNumber, this.text);

  final String bookId;
  final int chapter, verseNumber;
  final String text;
}

final _valuesRowPattern = RegExp(
  r"\(\s*'([^']+)'\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*'([^']+)'\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)",
);

List<RawCrossRef> parseCrossRefSql(String combinedSql) {
  final results = <RawCrossRef>[];
  for (final match in _valuesRowPattern.allMatches(combinedSql)) {
    results.add(
      RawCrossRef(
        fromBook: match.group(1)!,
        fromChapter: int.parse(match.group(2)!),
        fromVerse: int.parse(match.group(3)!),
        toBook: match.group(4)!,
        toChapter: int.parse(match.group(5)!),
        toVerseStart: int.parse(match.group(6)!),
        toVerseEnd: int.parse(match.group(7)!),
        votes: int.parse(match.group(8)!),
      ),
    );
  }
  return results;
}

/// Reads all 7 chunked cross_references_N.sql files and returns their
/// concatenated text content as a single string, in file order.
String loadCombinedCrossRefSql(String sourceDir) {
  final buffer = StringBuffer();
  for (var i = 0; i <= 6; i++) {
    final file = File('$sourceDir/cross_references_$i.sql');
    if (!file.existsSync()) {
      throw StateError('Missing expected file: cross_references_$i.sql');
    }
    buffer.writeln(file.readAsStringSync());
  }
  return buffer.toString();
}

List<RawVerse> parseUsfx(String xmlContent) {
  final doc = XmlDocument.parse(xmlContent);
  final verses = <RawVerse>[];

  for (final bookEl in doc.findAllElements('book')) {
    final bookId = bookEl.getAttribute('id')!;
    int currentChapter = 0;
    int currentVerse = 0;
    final buffer = StringBuffer();

    void flush() {
      if (currentVerse > 0 && buffer.toString().trim().isNotEmpty) {
        verses.add(
          RawVerse(bookId, currentChapter, currentVerse, buffer.toString()),
        );
      }
      buffer.clear();
    }

    for (final node in bookEl.descendants) {
      if (node is XmlElement && node.name.local == 'c') {
        flush();
        currentChapter = int.parse(node.getAttribute('id')!);
        currentVerse = 0;
      } else if (node is XmlElement && node.name.local == 'v') {
        flush();
        currentVerse = _parseVerseId(node.getAttribute('id')!);
      } else if (node is XmlText) {
        buffer.write(node.value);
      }
      // ignore all other markers (poetry/paragraph/footnote tags)
    }
    flush();
  }

  return verses;
}

String _formatReference(int book, int chapter, int verse) {
  return '${bookNumberToName[book]} $chapter:$verse';
}

/// USFX verse `id` attributes are usually a plain integer ("16"), but for
/// verse bridges (a single span of text covering multiple verse numbers,
/// e.g. some Psalm titles or historical-book variants) the id can be a
/// range like "15-16". We key on the first verse number of the bridge;
/// the bridged text is stored under that starting verse.
int _parseVerseId(String id) {
  final firstToken = id.split(RegExp(r'[-,]')).first.trim();
  return int.parse(firstToken);
}

const usfxBookIdToNumber = <String, int>{
  'GEN': 1,
  'EXO': 2,
  'LEV': 3,
  'NUM': 4,
  'DEU': 5,
  'JOS': 6,
  'JDG': 7,
  'RUT': 8,
  '1SA': 9,
  '2SA': 10,
  '1KI': 11,
  '2KI': 12,
  '1CH': 13,
  '2CH': 14,
  'EZR': 15,
  'NEH': 16,
  'EST': 17,
  'JOB': 18,
  'PSA': 19,
  'PRO': 20,
  'ECC': 21,
  'SNG': 22,
  'ISA': 23,
  'JER': 24,
  'LAM': 25,
  'EZK': 26,
  'DAN': 27,
  'HOS': 28,
  'JOL': 29,
  'AMO': 30,
  'OBA': 31,
  'JON': 32,
  'MIC': 33,
  'NAM': 34,
  'HAB': 35,
  'ZEP': 36,
  'HAG': 37,
  'ZEC': 38,
  'MAL': 39,
  'MAT': 40,
  'MRK': 41,
  'LUK': 42,
  'JHN': 43,
  'ACT': 44,
  'ROM': 45,
  '1CO': 46,
  '2CO': 47,
  'GAL': 48,
  'EPH': 49,
  'PHP': 50,
  'COL': 51,
  '1TH': 52,
  '2TH': 53,
  '1TI': 54,
  '2TI': 55,
  'TIT': 56,
  'PHM': 57,
  'HEB': 58,
  'JAS': 59,
  '1PE': 60,
  '2PE': 61,
  '1JH': 62,
  '2JH': 63,
  '3JH': 64,
  'JUD': 65,
  'REV': 66,
};

const fullBookNameToNumber = <String, int>{
  'Genesis': 1,
  'Exodus': 2,
  'Leviticus': 3,
  'Numbers': 4,
  'Deuteronomy': 5,
  'Joshua': 6,
  'Judges': 7,
  'Ruth': 8,
  '1 Samuel': 9,
  '2 Samuel': 10,
  '1 Kings': 11,
  '2 Kings': 12,
  '1 Chronicles': 13,
  '2 Chronicles': 14,
  'Ezra': 15,
  'Nehemiah': 16,
  'Esther': 17,
  'Job': 18,
  'Psalms': 19,
  'Proverbs': 20,
  'Ecclesiastes': 21,
  'Song of Solomon': 22,
  'Isaiah': 23,
  'Jeremiah': 24,
  'Lamentations': 25,
  'Ezekiel': 26,
  'Daniel': 27,
  'Hosea': 28,
  'Joel': 29,
  'Amos': 30,
  'Obadiah': 31,
  'Jonah': 32,
  'Micah': 33,
  'Nahum': 34,
  'Habakkuk': 35,
  'Zephaniah': 36,
  'Haggai': 37,
  'Zechariah': 38,
  'Malachi': 39,
  'Matthew': 40,
  'Mark': 41,
  'Luke': 42,
  'John': 43,
  'Acts of the Apostles': 44,
  'Romans': 45,
  '1 Corinthians': 46,
  '2 Corinthians': 47,
  'Galatians': 48,
  'Ephesians': 49,
  'Philippians': 50,
  'Colossians': 51,
  '1 Thessalonians': 52,
  '2 Thessalonians': 53,
  '1 Timothy': 54,
  '2 Timothy': 55,
  'Titus': 56,
  'Philemon': 57,
  'Hebrews': 58,
  'James': 59,
  '1 Peter': 60,
  '2 Peter': 61,
  '1 John': 62,
  '2 John': 63,
  '3 John': 64,
  'Jude': 65,
  'Revelation': 66,
};

final bookNumberToName = Map<int, String>.fromEntries(
  fullBookNameToNumber.entries.map((e) => MapEntry(e.value, e.key)),
);
