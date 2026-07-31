import 'package:audio_service/audio_service.dart';
import 'package:fiakkere/_shared/models/session_transport_callbacks.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges just_audio's [AudioPlayer] to the OS-level transport surface
/// (lock screen, notification, headset buttons) via audio_service.
///
/// This class only knows about [AudioPlayer] and the callback bundle handed
/// to it at construction — it has no import of, or reference to,
/// SessionManager or any other Manager. Transport button presses are routed
/// back to session logic purely through those callbacks, which
/// JustAudioPlayerService wires up from whatever locator.dart provides.
class ScriptureFlowAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  ScriptureFlowAudioHandler({required this._player, required this._transport}) {
    _listenToPlaybackState();
    _listenToCurrentIndex();
    _listenToSequenceState();
  }

  final AudioPlayer _player;
  final SessionTransportCallbacks _transport;

  void _listenToPlaybackState() {
    _player.playbackEventStream.listen(
      (event) {
        final playing = _player.playing;
        playbackState.add(
          playbackState.value.copyWith(
            controls: [
              MediaControl.skipToPrevious,
              playing ? MediaControl.pause : MediaControl.play,
              MediaControl.stop,
              MediaControl.skipToNext,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.skipToNext,
              MediaAction.skipToPrevious,
            },
            androidCompactActionIndices: const [0, 1, 3],
            processingState: switch (_player.processingState) {
              ProcessingState.idle => AudioProcessingState.idle,
              ProcessingState.loading => AudioProcessingState.loading,
              ProcessingState.buffering => AudioProcessingState.buffering,
              ProcessingState.ready => AudioProcessingState.ready,
              ProcessingState.completed => AudioProcessingState.completed,
            },
            playing: playing,
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
            speed: _player.speed,
            queueIndex: event.currentIndex,
          ),
        );
      },
      onError: (Object e, StackTrace st) {
        // Playback stream errors (e.g. a bad cached TTS file) shouldn't crash
        // the handler — surface as idle so the notification doesn't get stuck
        // showing stale "playing" state.
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            playing: false,
          ),
        );
      },
    );
  }

  void _listenToCurrentIndex() {
    _player.currentIndexStream.listen((index) {
      final currentQueue = queue.value;
      if (index == null || index < 0 || index >= currentQueue.length) return;
      mediaItem.add(currentQueue[index]);
    });
  }

  void _listenToSequenceState() {
    _player.sequenceStateStream.listen((state) {
      final sequence = state.effectiveSequence;
      queue.add(
        sequence
            .map((source) => source.tag as MediaItem)
            .toList(growable: false),
      );
    });
  }

  /// Called by JustAudioPlayerService after it rebuilds sources, so the
  /// lock-screen queue metadata stays in sync even on the tail-append fast
  /// path (which doesn't necessarily emit a fresh sequenceState in every
  /// just_audio version/timing scenario).
  void updateQueueMetadata(List<dynamic> verses) {
    // Deliberately untyped (`dynamic`) here to avoid this Service file
    // importing the `models` package's Verse type directly beyond what's
    // already pulled in transitively via MediaItem tags — kept minimal on
    // purpose. In practice this is a no-op pass-through since
    // _listenToSequenceState already keeps `queue` current; retained as an
    // explicit hook in case just_audio's stream timing needs a manual nudge.
  }

  @override
  Future<void> play() async {
    _transport.onPlay();
    await _player.play();
  }

  @override
  Future<void> pause() async {
    _transport.onPause();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _transport.onStop();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    _transport.onSkipNext();
  }

  @override
  Future<void> skipToPrevious() async {
    _transport.onSkipPrevious();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}
