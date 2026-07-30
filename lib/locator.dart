import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:fiakkere/features/playlist/manager/playlist_manager.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:fiakkere/features/session/manager/session_manager.dart';
import 'package:flutter_it/flutter_it.dart';

void configureDependencies() {
  di.registerSingletonAsync<Database>(Database.create);
  di.registerSingletonWithDependencies(
    () => ScriptureManager(di<Database>()),
    dependsOn: [Database],
  );
  di.registerSingletonWithDependencies(
    () => PlaylistManager(di<Database>()),
    dependsOn: [Database],
  );
  di.registerSingletonWithDependencies(
    () => SessionManager(),
    dependsOn: [Database, PlaylistManager],
  );
}
