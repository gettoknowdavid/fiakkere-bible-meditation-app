import 'package:fiakkere/_shared/models/session_transport_callbacks.dart';
import 'package:fiakkere/_shared/services/audio_player_service.dart';
import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:fiakkere/_shared/services/tts_service.dart';
import 'package:fiakkere/features/playlist/manager/playlist_manager.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:fiakkere/features/session/manager/session_manager.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:flutter_tts/flutter_tts.dart';

void configureDependencies() {
  di.registerSingleton(() => FlutterTts());

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

  di.registerSingletonAsync(() async => TtsCacheHelper());

  di.registerSingletonWithDependencies(() {
    final sessionManager = di<SessionManager>();
    final service = JustAudioPlayerService(
      ttsCache: di<TtsCacheHelper>(),
      transport: SessionTransportCallbacks(
        onPlay: sessionManager.resumeCommand.run,
        onPause: sessionManager.pauseCommand.run,
        onSkipNext: sessionManager.skipNextCommand.run,
        onSkipPrevious: () {},
        onStop: sessionManager.stopCommand.run,
      ),
    );
    service.attachQueue(
      queue: sessionManager.activeQueue,
      currentIndex: sessionManager.currentIndex,
    );
    return service;
  }, dependsOn: [SessionManager, TtsCacheHelper]);
}
