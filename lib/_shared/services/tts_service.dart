import 'dart:convert';
import 'dart:io';

import 'package:fiakkere/features/settings/models/voice_settings.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:models/models.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Wraps flutter_tts. Synthesizes a verse to a cached audio file on disk,
/// keyed by verse ID + a hash of voice settings, so a verse is only
/// synthesized once per device per voice configuration (TRD §2.2).
class TtsCacheHelper {
  TtsCacheHelper({this._settings = const VoiceSettings()});

  final FlutterTts _tts = FlutterTts();
  VoiceSettings _settings;

  Directory? _cacheDir;

  /// Called by SettingsManager (via locator wiring) when the user changes
  /// rate/pitch/voice — future synthesis calls use the new settings and
  /// hash to a new cache key, leaving old files as inert, evictable cache.
  void updateSettings(VoiceSettings settings) {
    _settings = settings;
  }

  Future<Directory> _getCacheDir() async {
    final existing = _cacheDir;
    if (existing != null) return existing;

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'tts_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _cacheFileName(Verse verse) =>
      'verse_${verse.id}_${_settings.cacheKeyFragment}.wav';

  /// Returns a cached file for [verse], synthesizing it first if this is
  /// the first time this verse has been played under the current voice
  /// settings.
  Future<File> synthesizeAndCache(Verse verse) async {
    final dir = await _getCacheDir();
    final file = File(p.join(dir.path, _cacheFileName(verse)));

    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    await _tts.setSpeechRate(_settings.rate);
    await _tts.setPitch(_settings.pitch);
    if (_settings.voice != null) {
      await _tts.setVoice({'name': _settings.voice!, 'locale': 'en-US'});
    }

    // flutter_tts's synthesizeToFile is platform-inconsistent (per TRD §8 —
    // confirm on a real device before relying on this in production; some
    // platform/OS combinations return before the file is fully flushed).
    final result = await _tts.synthesizeToFile(verse.text, file.path);
    if (result != 1) {
      throw StateError(
        'TTS synthesis failed for verse ${verse.id} (code $result)',
      );
    }

    return file;
  }

  /// Dev-only helper (T5.6) — not wired into any shipped UI.
  Future<void> clearCache() async {
    final dir = await _getCacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _cacheDir = null;
  }

  Future<int> cacheSizeInBytes() async {
    final dir = await _getCacheDir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
