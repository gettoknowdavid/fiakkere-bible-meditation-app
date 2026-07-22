import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:flutter_it/flutter_it.dart';

void configureDependencies() {
  di.registerSingletonAsync<Database>(Database.create);
}
