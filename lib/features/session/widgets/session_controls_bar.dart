import 'package:fiakkere/features/session/manager/session_manager.dart';
import 'package:fiakkere/features/session/model/session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';

class SessionControlsBar extends WatchingWidget {
  const SessionControlsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = di<SessionManager>();

    final state = watchValue<SessionManager, SessionState>(
      (m) => m.sessionState,
    );

    final canStop = watchValue<SessionManager, bool>(
      (m) => m.stopCommand.canRun,
    );

    final canPause = watchValue<SessionManager, bool>(
      (m) => m.pauseCommand.canRun,
    );

    final canResume = watchValue<SessionManager, bool>(
      (m) => m.resumeCommand.canRun,
    );

    final canSkipNext = watchValue<SessionManager, bool>(
      (m) => m.skipNextCommand.canRun,
    );

    final isPlaying = state == .playing;
    final isPaused = state == .paused;

    void handleStop() {
      manager.stopCommand.run();
      context.pop();
    }

    void handlePlayOrPause() {
      if (isPlaying) return manager.pauseCommand.run();
      if (isPaused) return manager.resumeCommand.run();
    }

    return Row(
      mainAxisAlignment: .spaceEvenly,
      children: [
        IconButton(
          onPressed: canStop ? handleStop : null,
          icon: Icon(Icons.stop),
        ),
        IconButton(
          onPressed: !(canResume || canPause) ? null : handlePlayOrPause,
          icon: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
        ),
        IconButton(
          onPressed: canSkipNext ? manager.skipNextCommand.run : null,
          icon: Icon(Icons.skip_next),
        ),
      ],
    );
  }
}
