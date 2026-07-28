import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:fiakkere/features/scripture/widgets/verse_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

class VerseSearchPage extends WatchingWidget {
  const VerseSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const _SearchField()),
      body: const _SearchResults(),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search verses…',
        border: InputBorder.none,
      ),
      onChanged: di<ScriptureManager>().searchCommand.run,
    );
  }
}

class _SearchResults extends WatchingWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    final results = watchValue((ScriptureManager m) => m.searchCommand.results);

    if (results.isRunning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!results.hasData || (results.data?.isEmpty ?? false)) {
      return const Center(child: Text('No matches yet'));
    }

    final verses = results.data!;

    return ListView.builder(
      itemCount: verses.length,
      itemBuilder: (context, index) => VerseTile(verse: verses[index]),
    );
  }
}
