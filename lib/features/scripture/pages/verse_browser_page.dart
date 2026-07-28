import 'package:fiakkere/_shared/routing/scripture_route.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:fiakkere/features/scripture/widgets/verse_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';
import 'package:models/models.dart';

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
          onTap: () => context.push(ChapterList(book: index + 1)),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }
}

class ChapterListPage extends WatchingWidget {
  const ChapterListPage({super.key, required this.book});

  final int book;

  @override
  Widget build(BuildContext context) {
    final bookName = Metadata.bookName(book);
    final chapters = Metadata.chapterCount(book);

    return Scaffold(
      appBar: AppBar(title: Text('Book $bookName')),
      body: GridView.builder(
        padding: const .all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: chapters,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          return _ChapterTile(book: book, chapter: chapter);
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.book, required this.chapter});

  final int book;
  final int chapter;

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

class VerseListPage extends WatchingWidget {
  const VerseListPage({required this.book, required this.chapter, super.key});

  final int book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    final bookName = Metadata.bookName(book);
    final verses = watchValue<ScriptureManager, List<Verse>>((m) => m.verses);

    return Scaffold(
      appBar: AppBar(title: Text('$bookName $chapter')),
      body: ListView.builder(
        itemCount: verses.length,
        itemBuilder: (context, index) => VerseTile(verse: verses[index]),
      ),
    );
  }
}
