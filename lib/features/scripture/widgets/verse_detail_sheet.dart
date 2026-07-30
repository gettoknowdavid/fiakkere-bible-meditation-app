import 'dart:developer';

import 'package:fiakkere/features/playlist/widgets/add_to_playlist_button.dart';
import 'package:fiakkere/features/scripture/manager/scripture_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:models/models.dart';

class VerseDetailSheet extends WatchingWidget {
  const VerseDetailSheet({super.key, required this.verseId});

  final int verseId;

  @override
  Widget build(BuildContext context) {
    final manager = di<ScriptureManager>();

    callOnce((context) {
      manager.getVerseCommand.run(verseId);
      manager.getCrossReferenceCommand.run(verseId);
    });

    final verse = watchValue((ScriptureManager m) => m.getVerseCommand.results);
    final crossRefs = watchValue<ScriptureManager, List<CrossReference>>(
      (m) => m.crossReferences,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        if (verse.isRunning) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!verse.hasData || verse.data == null) {
          return Text('Nothing to show here');
        }

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              verse.data!.reference,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              verse.data!.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            AddToPlaylistButton(verseId: verse.data!.id),
            const SizedBox(height: 24),
            if (crossRefs.isNotEmpty) ...[
              Text(
                'Related Verses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final ref in crossRefs) _RelatedVerseRow(ref: ref),
            ],
          ],
        );
      },
    );
  }
}

class _RelatedVerseRow extends WatchingWidget {
  const _RelatedVerseRow({required this.ref});

  final CrossReference? ref;

  @override
  Widget build(BuildContext context) {
    log('Cross Reference: $ref');

    final related = ref?.relatedVerse.target;
    if (related == null) return const SizedBox.shrink();

    return ListTile(
      dense: true,
      title: Text(related.reference),
      subtitle: Text(
        related.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.of(context).pop();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => VerseDetailSheet(verseId: related.id),
        );
      },
    );
  }
}
