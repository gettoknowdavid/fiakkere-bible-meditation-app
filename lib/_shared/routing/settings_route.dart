import 'package:kaisel/kaisel.dart';

sealed class SettingsRoute extends KaiselRoute {
  const SettingsRoute();
}

final class SettingsHome extends SettingsRoute {
  const SettingsHome();
}
