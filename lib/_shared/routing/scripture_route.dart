import 'package:kaisel/kaisel.dart';

sealed class ScriptureRoute extends KaiselRoute {
  const ScriptureRoute();
}

final class VerseBrowser extends ScriptureRoute {
  const VerseBrowser();
}

final class VerseSearch extends ScriptureRoute {
  const VerseSearch();
}

final class ChapterList extends ScriptureRoute {
  const ChapterList({required this.book});

  final int book;
}

final class VerseList extends ScriptureRoute {
  const VerseList({required this.book, required this.chapter});

  final int book;
  final int chapter;
}
