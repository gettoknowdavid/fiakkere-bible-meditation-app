import 'package:fiakkere/features/session/manager/session_manager.dart';
import 'package:fiakkere/features/session/widgets/session_controls_bar.dart';
import 'package:fiakkere/features/session/widgets/session_timer_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';
import 'package:models/models.dart';

class SessionPlayerPage extends WatchingWidget {
  const SessionPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    registerHandler(
      select: (SessionManager manager) => manager.sessionState,
      handler: (context, state, cancel) {
        if (state == .completed && context.mounted) context.pop();
      },
    );

    return Scaffold(
      body: Padding(
        padding: const .all(32.0),
        child: Column(
          children: [
            SizedBox(height: 32),
            Expanded(child: _CurrentVerseDisplay()),
            // RelatedVersePanel(),
            SessionTimerDisplay(),
            SessionControlsBar(),
          ],
        ),
      ),
    );
  }
}

class _CurrentVerseDisplay extends WatchingWidget {
  const _CurrentVerseDisplay();

  @override
  Widget build(BuildContext context) {
    final verses = watchValue<SessionManager, List<Verse>>(
      (m) => m.activeQueue,
    );
    final verse = watchValue<SessionManager, Verse?>((m) => m.currentVerse);
    final currentIndex = watchValue<SessionManager, int>((m) => m.currentIndex);
    if (verse == null) return SizedBox.shrink();

    final theme = Theme.of(context);

    return ListView.separated(
      itemBuilder: (context, index) {
        final isCurrent = currentIndex == index;

        final activeColor = theme.colorScheme.primary;
        final inActiveColor = theme.colorScheme.onSurface.withValues(alpha: .5);

        return Transform.scale(
          scale: isCurrent ? 1.0 : 0.95,
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                verse.reference,
                style: isCurrent
                    ? theme.textTheme.titleMedium?.copyWith(color: activeColor)
                    : theme.textTheme.titleMedium?.copyWith(color: inActiveColor),
              ),
              Text(
                verse.text,
                style: isCurrent
                    ? theme.textTheme.headlineSmall?.copyWith(color: activeColor)
                    : theme.textTheme.headlineSmall?.copyWith(
                        color: inActiveColor,
                      ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemCount: verses.length,
    );
  }
}
