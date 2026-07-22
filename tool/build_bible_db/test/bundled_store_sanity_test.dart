import 'package:build_bible_db/models/verse.dart';
import 'package:build_bible_db/objectbox.g.dart';
import 'package:test/test.dart';

void main() {
  late Store store;

  setUpAll(() {
    // Point at the same output the build script wrote (or a copy of the
    // unzipped app store dir) — this test validates T1.3/T1.4 output directly.
    store = openStore(directory: 'build_output/objectbox');
  });

  tearDownAll(() => store.close());

  test('verse count is approximately correct', () {
    final count = store.box<Verse>().count();
    expect(count, greaterThan(30000));
    expect(count, lessThan(32000));
  });

  test('John 3:16 text matches known WEB wording', () {
    final query = store
        .box<Verse>()
        .query(Verse_.reference.equals('John 3:16'))
        .build();
    final verse = query.findFirst();
    query.close();
    expect(verse, isNotNull);
    expect(verse!.text, contains('For God so loved the world'));
  });

  test('a known TSK cross-reference resolves via ToOne', () {
    final query = store
        .box<Verse>()
        .query(Verse_.reference.equals('Genesis 1:1'))
        .build();
    final genesis11 = query.findFirst()!;
    query.close();
    expect(genesis11.crossReferences, isNotEmpty);
    expect(genesis11.crossReferences.first.relatedVerse.target, isNotNull);
  });
}
