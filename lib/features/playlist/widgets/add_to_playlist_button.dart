import 'dart:developer';

import 'package:fiakkere/features/playlist/manager/playlist_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';
import 'package:models/models.dart';

class AddToPlaylistButton extends StatelessWidget {
  const AddToPlaylistButton({required this.verseId, super.key});

  final int verseId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.playlist_add),
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (_) => _PlaylistPickerSheet(verseId: verseId),
      ),
    );
  }
}

class _PlaylistPickerSheet extends WatchingWidget {
  const _PlaylistPickerSheet({required this.verseId});

  final int verseId;

  @override
  Widget build(BuildContext context) {
    registerHandler(
      select: (PlaylistManager manager) => manager.createPlaylistCommand,
      handler: (context, newPlaylist, cancel) {
        if (newPlaylist != null && context.mounted) {
          final args = AddVerseArgs(
            playlistId: newPlaylist.id,
            verseId: verseId,
          );
          di<PlaylistManager>().addVerseCommand.run(args);
          context.pop();
        }
      },
    );

    final playlists = watchValue<PlaylistManager, List<MeditationPlaylist>>(
      (m) => m.playlists,
    );
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Add to playlist',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New Playlist…'),
            onTap: () => _createAndAdd(context),
          ),
          if (playlists.isNotEmpty) const Divider(),
          for (final playlist in playlists)
            ListTile(
              title: Text(playlist.name),
              subtitle: Text('${playlist.items.length} verses'),
              onTap: () {
                di<PlaylistManager>().addVerseCommand.run(
                  AddVerseArgs(playlistId: playlist.id, verseId: verseId),
                );
                context.pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final name = await _showNameDialog(context);
    log('Name is $name');
    if (name == null || name.trim().isEmpty) return;

    final manager = di<PlaylistManager>();
    manager.createPlaylistCommand.run(name.trim());
  }

  Future<String?> _showNameDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Playlist name'),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
