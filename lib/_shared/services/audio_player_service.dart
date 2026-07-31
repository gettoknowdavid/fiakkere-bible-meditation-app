import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:fiakkere/_shared/models/session_transport_callbacks.dart';
import 'package:fiakkere/_shared/services/scripture_flow_audio_handler.dart';
import 'package:fiakkere/_shared/services/tts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:models/models.dart';

/// The TRD's one deliberate interface exception (TRD §2.2, §6): a thin seam
/// so a future cloud-TTS/streaming provider can be swapped in without
/// touching call sites. `JustAudioPlayerService` is the only MVP
/// implementation.
abstract class AudioPlayerService {
  Future<void> attachQueue({
    required ValueListenable<List<Verse>> queue,
    required ValueListenable<int> currentIndex,
  });

  Future<void> play();

  Future<void> pause();

  Future<void> seekToIndex(int index);

  Future<void> dispose();
}

/// just_audio + audio_service implementation. Knows nothing about
/// SessionManager or any other Manager — it only consumes ValueListenables
/// and exposes callback slots. Registered as a lazy singleton in
/// locator.dart, where the wiring to SessionManager actually happens.
class JustAudioPlayerService implements AudioPlayerService {
  JustAudioPlayerService({required this._ttsCache, required this._transport}) {
    _handler = ScriptureFlowAudioHandler(
      player: _player,
      transport: _transport,
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final TtsCacheHelper _ttsCache;
  final SessionTransportCallbacks _transport;

  late final ScriptureFlowAudioHandler _handler;

  ValueListenable<List<Verse>>? _queue;
  ValueListenable<int>? _currentIndex;
  ListenableSubscription? _queueSubscription;

  /// The verse-id list mirrored into the player the last time we rebuilt
  /// sources — used to diff against the incoming queue so we only touch
  /// just_audio when something actually changed, per TRD §3.3 point 3
  /// ("mirrors additions/removals... without interrupting playback").
  List<int> _mirroredVerseIds = const [];

  @override
  Future<void> attachQueue({
    required ValueListenable<List<Verse>> queue,
    required ValueListenable<int> currentIndex,
  }) async {
    _queue = queue;
    _currentIndex = currentIndex;

    // Build sources for whatever is already in the queue at attach time.
    await _rebuildSources(queue.value);

    // React to every future queue mutation. listen_it's listen() (not
    // addListener) per the architecture skill, so we get a
    // ListenableSubscription we can cancel on dispose.
    _queueSubscription = queue.listen((verses, _) {
      // Fire and forget from the sync listener callback; errors surface via
      // the returned future's unhandled-error zone, which is acceptable
      // here since play/synthesis failures are already user-visible via
      // playback stalling — a dedicated error surface can be added if this
      // becomes a problem in practice.
      unawaited(_rebuildSources(verses));
    });

    currentIndex.listen((index, _) {
      final playerIndex = _player.currentIndex;
      if (playerIndex != index &&
          index >= 0 &&
          index < _mirroredVerseIds.length) {
        unawaited(_player.seek(Duration.zero, index: index));
      }
    });
  }

  Future<void> _rebuildSources(List<Verse> verses) async {
    final incomingIds = verses.map((v) => v.id).toList(growable: false);

    if (listEquals(incomingIds, _mirroredVerseIds)) return;

    final diff = _diffAdditions(previous: _mirroredVerseIds, next: incomingIds);

    // MVP simplification: TSK injection only ever appends to the tail of
    // the queue (SessionManager never reorders or removes mid-session), so
    // a tail-append diff is sufficient. If that assumption changes, this
    // needs a real positional diff instead.
    if (diff.isTailAppend) {
      for (final verseId in diff.addedIds) {
        final verse = verses.firstWhere((v) => v.id == verseId);
        final source = await _sourceFor(verse);
        _player.audioSource == null
            ? _setInitialSources(verses)
            : _player.audioSource!.add(source);
      }
    } else {
      // Non-append change (e.g. stop/clear/new session) — full rebuild.
      await _setInitialSources(verses);
    }

    _mirroredVerseIds = incomingIds;
    _handler.updateQueueMetadata(verses);
  }

  Future<void> _setInitialSources(List<Verse> verses) async {
    if (verses.isEmpty) {
      await _player.stop();
      return;
    }
    final sources = <AudioSource>[];
    for (final verse in verses) {
      sources.add(await _sourceFor(verse));
    }
    // just_audio's modern replacement for the deprecated
    // ConcatenatingAudioSource-as-primary-API pattern: setAudioSources
    // builds/updates the whole playlist in one call.
    await _player.setAudioSources(sources, initialIndex: 0);
  }

  Future<AudioSource> _sourceFor(Verse verse) async {
    final file = await _ttsCache.synthesizeAndCache(verse);
    return AudioSource.uri(
      Uri.file(file.path),
      tag: MediaItem(
        id: verse.id.toString(),
        title: verse.reference,
        album: 'ScriptureFlow',
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekToIndex(int i) => _player.seek(Duration.zero, index: i);

  @override
  Future<void> dispose() async {
    _queueSubscription?.cancel();
    await _player.dispose();
  }
}

/// Result of diffing two verse-id lists, used to decide whether the queue
/// change is a simple tail-append (fast path: mirror without disrupting
/// playback) or something more disruptive (full rebuild).
class _QueueDiff {
  const _QueueDiff({required this.isTailAppend, required this.addedIds});

  final bool isTailAppend;
  final List<int> addedIds;
}

_QueueDiff _diffAdditions({
  required List<int> previous,
  required List<int> next,
}) {
  final isTailAppend =
      next.length >= previous.length &&
      listEquals(next.sublist(0, previous.length), previous);

  if (!isTailAppend) {
    return const _QueueDiff(isTailAppend: false, addedIds: []);
  }

  return _QueueDiff(
    isTailAppend: true,
    addedIds: next.sublist(previous.length),
  );
}
