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

final class VerseDetail extends ScriptureRoute {
  const VerseDetail(this.verseId);

  final int verseId;

  @override
  List<Object?> get props => [verseId];
}
