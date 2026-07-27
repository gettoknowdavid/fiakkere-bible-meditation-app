import 'package:fiakkere/_shared/models/verse.dart';
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
    return ListTile(
      title: Text(
        verse.reference,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      subtitle: Text(verse.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
