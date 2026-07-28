import 'package:bible_models/bible_models.dart';
import 'package:fiakkere/features/scripture/widgets/verse_detail_sheet.dart';
import 'package:flutter/material.dart';

/// Stateless — no manager state to watch here, so a plain widget is
/// correct (not everything needs to be a WatchingWidget; only widgets
/// that actually read reactive state do).
class VerseTile extends StatelessWidget {
  const VerseTile({super.key, required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Align(
        alignment: .centerLeft,
        child: Container(
          padding: .symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: .all(.circular(20)),
            color: theme.colorScheme.primary,
          ),
          child: Text(
            verse.reference,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      subtitle: Padding(
        padding: const .all(8.0),
        child: Text(verse.text, style: theme.textTheme.bodyLarge),
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (_) => VerseDetailSheet(verseId: verse.id),
      ),
      // Long-press entry point for "Add to Playlist" — stubbed per T2.4,
      // wired for real in T3.3 once PlaylistManager exists.
      onLongPress: () {
        // TODO(T3.3): open AddToPlaylistButton picker via PlaylistManager.
      },
    );
  }
}
