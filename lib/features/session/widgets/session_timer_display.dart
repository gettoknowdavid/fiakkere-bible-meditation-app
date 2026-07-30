import 'package:fiakkere/features/session/manager/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';

class SessionTimerDisplay extends WatchingWidget {
  const SessionTimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final secs = watchValue<SessionManager, int>((m) => m.remainingSeconds);
    final formatted = _formatMmSs(secs);
    return Text(formatted);
  }

  String _formatMmSs(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "-$minutes:$seconds";
  }
}
