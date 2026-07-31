import 'package:flutter/foundation.dart';

class SessionTransportCallbacks {
  const SessionTransportCallbacks({
    required this.onPlay,
    required this.onPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onStop,
  });

  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onStop;
}
