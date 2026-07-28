import 'package:bible_models/bible_models.dart';
import 'package:fiakkere/_shared/routing/scripture_route.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:fiakkere/features/scripture/widgets/verse_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';

class VerseBrowserPage extends StatelessWidget {
  const VerseBrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(VerseSearch()),
          ),
        ],
      ),
      body: const _BookList(),
    );
  }
}

class _BookList extends WatchingWidget {
  const _BookList();

  @override
  Widget build(BuildContext context) {
    final manager = di<ScriptureManager>();
    final books = manager.bookNames;
    return ListView.separated(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final bookName = books[index];
        return ListTile(
          title: Text(bookName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(ChapterList(index + 1)),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }
}

class ChapterListPage extends WatchingWidget {
  const ChapterListPage({required this.book, super.key});

  final int book;

  @override
  Widget build(BuildContext context) {
    final manager = di<ScriptureManager>();
    callOnce((context) => manager.setBook(book));

    final currentChapter = watchValue<ScriptureManager, int>((m) => m.chapter);
    final chapters = manager.chapterCount(book);

    return Scaffold(
      appBar: AppBar(title: Text('Book ${manager.currentBookName}')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: chapters,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          final isSelected = chapter == currentChapter;
          return _ChapterTile(
            book: book,
            chapter: chapter,
            isSelected: isSelected,
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.book,
    required this.chapter,
    this.isSelected = false,
  });

  final int book;
  final int chapter;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        final args = ScriptureArgs(book: book, chapter: chapter);
        di<ScriptureManager>().getVersesCommand.run(args);
        context.push(VerseList(book: book, chapter: chapter));
      },
      style: OutlinedButton.styleFrom(padding: .zero),
      child: Text('$chapter'),
    );
  }
}

/// Isolated per-chapter verse list — this is the widget that actually
/// watches manager state; scoping it here means selecting a different
/// chapter never rebuilds the book/chapter grid above it.
class VerseListPage extends WatchingWidget {
  const VerseListPage({required this.book, required this.chapter, super.key});

  final int book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    final manager = di<ScriptureManager>();

    final verses = watchValue<ScriptureManager, List<Verse>>((m) => m.verses);

    return Scaffold(
      appBar: AppBar(title: Text('${manager.currentBookName} $chapter')),
      body: ListView.builder(
        itemCount: verses.length,
        itemBuilder: (context, index) => VerseTile(verse: verses[index]),
      ),
    );
  }
}
