import 'dart:async';
import 'dart:developer';

import 'package:bible_models/bible_models.dart';
import 'package:fiakkere/_shared/models/bible_metadata.dart';
import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:sqflite/sqflite.dart';

class ScriptureManager implements Disposable {
  ScriptureManager(this._databaseService) {
    searchQueryCommand = Command.createSync((query) => query, initialValue: '');
    searchCommand = Command.createAsync(_runSearch, initialValue: const []);
    getVersesCommand = Command.createAsyncNoResult((args) async {
      book.value = args.book;
      chapter.value = args.chapter;
      verse.value = args.verse;
      final trans = args.translation.isNotEmpty
          ? args.translation
          : translation.value;

      final resultMaps = await _db.query(
        'verses',
        where: 'translation = ? AND book = ? AND chapter = ?',
        whereArgs: [trans, book.value, chapter.value],
        orderBy: 'verse ASC',
      );

      final result = resultMaps.map((m) => Verse.fromMap(m)).toList();
      log('Result of the verses query => ${result.length} verses loaded');

      verses.startTransAction();
      verses.clear();
      verses.addAll(result);
      verses.endTransAction();
    });
    getVerseCommand = Command.createAsync((verseId) async {
      final resultMaps = await _db.query(
        'verses',
        where: 'id = ? AND translation = ?',
        whereArgs: [verseId, translation.value],
        orderBy: 'verse ASC',
        limit: 1,
      );

      if (resultMaps.isNotEmpty) return Verse.fromMap(resultMaps.first);
      return null;
    }, initialValue: null);
    getCrossReferenceCommand = Command.createAsyncNoResult((verseId) async {
      final results = await _db.rawQuery(
        '''
        SELECT 
          cr.id AS cr_id,
          cr.sourceVerseId,
          cr.relatedVerseId,
          cr.weight,
          v.id AS v_id,
          v.reference,
          v.universalKey,
          v.book,
          v.chapter,
          v.verse,
          v.text,
          v.translation
        FROM cross_references cr
        INNER JOIN verses v ON cr.relatedVerseId = v.id
        WHERE cr.sourceVerseId = ?
        ORDER BY cr.weight DESC
      ''',
        [verseId],
      );

      final list = results.map((row) {
        final relatedVerse = Verse(
          id: row['v_id'] as int,
          reference: row['reference'] as String,
          universalKey: row['universalKey'] as String,
          book: row['book'] as int,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          text: row['text'] as String,
          translation: row['translation'] as String,
        );

        return CrossReference(
          id: row['cr_id'] as int,
          sourceVerseId: row['sourceVerseId'] as int,
          relatedVerseId: row['relatedVerseId'] as int,
          weight: row['weight'] as int,
          relatedVerse: relatedVerse,
        );
      }).toList();

      crossReferences.startTransAction();
      crossReferences.clear();
      crossReferences.addAll(list);
      crossReferences.endTransAction();
    });

    _searchQuerySubscription = searchQueryCommand
        .debounce(Duration(milliseconds: 300))
        .where((text) => text.isNotEmpty)
        .pipeToCommand(searchCommand);
  }

  final DatabaseService _databaseService;

  Database get _db => _databaseService.db;

  late final Command<String, String> searchQueryCommand;
  late final Command<String, List<Verse>> searchCommand;
  late final Command<ScriptureArgs, void> getVersesCommand;
  late final Command<int, Verse?> getVerseCommand;
  late final Command<int, void> getCrossReferenceCommand;

  final book = ValueNotifier<int>(0);
  final chapter = ValueNotifier<int>(1);
  final verse = ValueNotifier<int>(1);
  final translation = ValueNotifier<String>('WEB');

  final verses = ListNotifier<Verse>(data: []);
  final crossReferences = ListNotifier<CrossReference>(data: []);

  late final ListenableSubscription _searchQuerySubscription;

  List<int> get books => BibleMetadata.books.keys.toList();

  List<String> get bookNames => BibleMetadata.bookNames;

  void setBook(int value) => book.value = value;

  String bookName(int id) => BibleMetadata.bookName(id);

  /// Get the current book name
  String get currentBookName => BibleMetadata.bookName(book.value);

  /// Chapter count for the currently active book.
  int chapterCount(int book) => BibleMetadata.chapterCount(book);

  /// Verse count for the currently active chapter.
  int get verseCount => BibleMetadata.verseCount(book.value, chapter.value);

  Future<List<Verse>> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    // Using SQL LIKE for text matching
    final resultMaps = await _db.query(
      'verses',
      where: 'text LIKE ?',
      whereArgs: ['%$trimmed%'],
      orderBy: 'book ASC, chapter ASC, verse ASC',
    );

    return resultMaps.map((m) => Verse.fromMap(m)).toList();
  }

  @override
  FutureOr<dynamic> onDispose() {
    _searchQuerySubscription.cancel();
    searchQueryCommand.dispose();
    searchCommand.dispose();
  }
}

class ScriptureArgs {
  const ScriptureArgs({
    this.book = 0,
    this.chapter = 1,
    this.verse = 1,
    this.translation = 'WEB',
  });

  final int book;
  final int chapter;
  final int verse;
  final String translation;

  ScriptureArgs copyWith({
    int? book,
    int? chapter,
    int? verse,
    String? translation,
  }) {
    return ScriptureArgs(
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      translation: translation ?? this.translation,
    );
  }
}
