import 'package:kaisel/kaisel.dart';

sealed class ScriptureRoute extends KaiselRoute {
  const ScriptureRoute();
}

final class ChapterList extends ScriptureRoute {
  const ChapterList(this.book);

  final int book;

  @override
  List<Object?> get props => [book];
}

final class VerseBrowser extends ScriptureRoute {
  const VerseBrowser();
}

final class VerseSearch extends ScriptureRoute {
  const VerseSearch();
}

final class VerseList extends ScriptureRoute {
  const VerseList({required this.book, required this.chapter});

  final int book;
  final int chapter;

  @override
  List<Object?> get props => [book, chapter];
}
