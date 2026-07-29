import 'dart:async';

import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:models/models.dart';

class ScriptureManager implements Disposable {
  ScriptureManager(this._database) {
    searchQueryCommand = Command.createSync((query) => query, initialValue: '');
    searchCommand = Command.createAsync(_runSearch, initialValue: const []);
    getVersesCommand = Command.createSyncNoResult((args) {
      book.value = args.book;
      chapter.value = args.chapter;
      verse.value = args.verse;
      final trans = args.translation.isNotEmpty
          ? args.translation
          : translation.value;

      final query = _verseBox
          .query(
            Verse_.book.equals(args.book) &
                Verse_.chapter.equals(args.chapter) &
                Verse_.translation.equals(trans),
          )
          .order(Verse_.verse)
          .build();

      try {
        final result = query.find();
        verses.startTransAction();
        verses.clear();
        verses.addAll(result);
        verses.endTransAction();
      } finally {
        query.close();
      }
    });
    getVerseCommand = Command.createSync((verseId) {
      final query = _verseBox
          .query(
            Verse_.id.equals(verseId) &
                Verse_.translation.equals(translation.value),
          )
          .order(Verse_.verse)
          .build();

      try {
        final result = query.find();
        return result[0];
      } finally {
        query.close();
      }
    }, initialValue: null);
    getCrossReferenceCommand = Command.createSyncNoResult((verse) {
      final query = _crossRefBox
          .query(CrossReference_.sourceVerse.equals(verse))
          .order(CrossReference_.weight, flags: Order.descending)
          .build();
      try {
        final result = query.find();
        crossReferences.startTransAction();
        crossReferences.clear();
        crossReferences.addAll(result);
        crossReferences.endTransAction();
      } finally {
        query.close();
      }
    });

    _searchQuerySubscription = searchQueryCommand
        .debounce(Duration(milliseconds: 300))
        .where((text) => text.isNotEmpty)
        .pipeToCommand(searchCommand);
  }

  final Database _database;

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

  Box<Verse> get _verseBox => _database.store.box<Verse>();

  Box<CrossReference> get _crossRefBox => _database.store.box<CrossReference>();

  List<int> get books => Metadata.books.keys.toList();

  List<String> get bookNames => Metadata.bookNames;

  String bookName(int id) => Metadata.bookName(id);

  /// Verse count for the currently active chapter.
  int get verseCount => Metadata.verseCount(book.value, chapter.value);

  Future<List<Verse>> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final q = (_verseBox.query(
      Verse_.text.contains(trimmed, caseSensitive: false),
    )).order(Verse_.book).build();

    try {
      return q.find();
    } finally {
      q.close();
    }
  }

  @override
  FutureOr<dynamic> onDispose() {
    _searchQuerySubscription.cancel();

    searchQueryCommand.dispose();
    searchCommand.dispose();
    getVersesCommand.dispose();
    getVerseCommand.dispose();
    getCrossReferenceCommand.dispose();

    book.dispose();
    chapter.dispose();
    verse.dispose();
    translation.dispose();
    verses.dispose();
    crossReferences.dispose();
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
