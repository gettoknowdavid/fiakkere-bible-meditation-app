import 'dart:async';

import 'package:fiakkere/features/session/model/session_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:models/models.dart';

class SessionManager implements Disposable {
  SessionManager() {
    startCommand = Command.createSyncNoResult(_start);
    pauseCommand = Command.createSyncNoParamNoResult(_pause);
    resumeCommand = Command.createSyncNoParamNoResult(_resume);
    stopCommand = Command.createSyncNoParamNoResult(_stop);
    skipNextCommand = Command.createSyncNoParamNoResult(_skipNext);
  }

  final activeQueue = ListNotifier<Verse>(data: []);

  final currentIndex = ValueNotifier<int>(0);
  final sessionState = ValueNotifier<SessionState>(.idle);

  final remainingSeconds = ValueNotifier<int>(0);

  ValueListenable<Verse?> get currentVerse =>
      activeQueue.combineLatest(currentIndex, (queue, index) {
        if (index < 0 || index >= queue.length) return null;
        return queue[index];
      });

  final _injectedVerseIds = <int>{};
  // final _maxQueueLength = 50;

  Timer? _ticker;
  int _totalDurationInSeconds = 0;

  late final Command<List<PlaylistItem>, void> startCommand;
  late final Command<void, void> pauseCommand;
  late final Command<void, void> resumeCommand;
  late final Command<void, void> stopCommand;
  late final Command<void, void> skipNextCommand;

  void _start(List<PlaylistItem> items) {
    final verses = items
        .map((item) => item.verse.target)
        .whereType<Verse>()
        .toList();

    if (verses.isEmpty) throw StateError('Playlist has no verses');

    activeQueue.startTransAction();
    activeQueue.clear();
    activeQueue.addAll(verses);
    activeQueue.endTransAction();

    currentIndex.value = 0;
    _injectedVerseIds.clear();
    sessionState.value = .playing;

    _startTimer(60);
  }

  void _pause() {
    sessionState.value = .paused;
    _pauseTimer();
  }

  void _resume() {
    sessionState.value = .playing;
    _resumeTimer();
  }

  void _stop() {
    sessionState.value = .idle;
    _cancelTimer();
    activeQueue.clear();
    currentIndex.value = 0;
    _injectedVerseIds.clear();
  }

  void _skipNext() {
    if (currentIndex.value + 1 < activeQueue.length) {
      currentIndex.value += 1;
    } else {
      _handleQueueExhausted();
    }
  }

  void onVerseCompleted() {
    // Handle related verse injection here
  }

  void _startTimer(int minutes) {
    _totalDurationInSeconds = 60 * minutes;
    remainingSeconds.value = _totalDurationInSeconds;
    _ticker?.cancel();
    _ticker = Timer.periodic(Duration(seconds: 1), (timer) {
      if (sessionState.value != .playing) return;
      if (remainingSeconds.value <= 0) {
        _stop();
        return;
      }
      remainingSeconds.value -= 1;
    });
  }

  void _pauseTimer() {}

  void _resumeTimer() {}

  void _cancelTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _handleQueueExhausted() {
    sessionState.value = .completed;
    _cancelTimer();
  }

  @override
  FutureOr<dynamic> onDispose() {
    _cancelTimer();

    activeQueue.dispose();
    currentIndex.dispose();
    sessionState.dispose();

    remainingSeconds.dispose();

    startCommand.dispose();
    pauseCommand.dispose();
    resumeCommand.dispose();
    stopCommand.dispose();
    skipNextCommand.dispose();
  }
}
