import 'package:fiakkere/_shared/manager/interaction_manager.dart';
import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:flutter_it/flutter_it.dart';

void configureDependencies() {
  di.registerSingleton<InteractionManager>(InteractionManager());
  di.registerSingletonAsync<Database>(Database.create);

  di.registerSingletonWithDependencies<ScriptureManager>(
    () => ScriptureManager(di<Database>()),
    dependsOn: [Database],
  );
}
