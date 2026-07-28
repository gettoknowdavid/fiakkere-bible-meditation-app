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

final class VerseList extends ScriptureRoute {
  const VerseList({required this.book, required this.chapter});

  final int book;
  final int chapter;
}