import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Voice parameters that affect the synthesized audio — hashed into the
/// cache key so a settings change (rate/pitch/voice) invalidates old cache
/// entries instead of silently reusing them.

class VoiceSettings {
  const VoiceSettings({
    this.rate = kDefaultCalmRate,
    this.pitch = kDefaultCalmPitch,
    this.voice,
    this.languageCode = 'en-US',
  });

  final double rate;
  final double pitch;
  final String? voice;
  final String languageCode;

  static const kDefaultCalmRate = 0.42;
  static const kDefaultCalmPitch = 0.95;

  VoiceSettings copyWith({
    double? rate,
    double? pitch,
    String? voice,
    String? languageCode,
  }) {
    return VoiceSettings(
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      voice: voice ?? this.voice,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  String get cacheKeyFragment {
    final raw = '$rate|$pitch|${voice ?? 'default'}';
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 12);
  }
}
