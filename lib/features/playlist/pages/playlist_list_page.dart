import 'package:fiakkere/_shared/routing/playlist_route.dart';
import 'package:fiakkere/features/playlist/manager/playlist_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:kaisel/kaisel.dart';
import 'package:models/models.dart';

class PlaylistListPage extends WatchingWidget {
  const PlaylistListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditation Playlists')),
      body: const _PlaylistList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final name = await _showNameDialog(context, title: 'New Playlist');
    if (name == null || name.trim().isEmpty) return;
    di<PlaylistManager>().createPlaylistCommand.run(name.trim());
  }
}

class _PlaylistList extends WatchingWidget {
  const _PlaylistList();

  @override
  Widget build(BuildContext context) {
    final playlists = watchValue<PlaylistManager, List<MeditationPlaylist>>(
      (m) => m.playlists,
    );

    if (playlists.isEmpty) {
      return const Center(
        child: Text('No playlists yet — create one to get started'),
      );
    }

    return ListView.separated(
      itemCount: playlists.length,
      itemBuilder: (ctx, i) => _PlaylistRow(playlist: playlists[i]),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlist});

  final MeditationPlaylist playlist;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(playlist.name),
      subtitle: Text('${playlist.items.length} verses'),
      onTap: () => context.push(PlaylistDetail(playlist.id)),
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) {
          return const [
            PopupMenuItem<String>(value: 'Rename', child: Text('Rename')),
            PopupMenuItem<String>(value: 'Delete', child: Text('Delete')),
          ];
        },
        onSelected: (action) {
          switch (action) {
            case 'Rename':
              _showRenameDialog(context, playlist);
            case 'Delete':
              _confirmAndDeleteDialog(context, playlist.id);
          }
        },
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    MeditationPlaylist playlist,
  ) async {
    final name = await _showNameDialog(
      context,
      title: 'Rename Playlist',
      initialValue: playlist.name,
    );
    if (name == null || name.trim().isEmpty) return;
    di<PlaylistManager>().renamePlaylistCommand.run(
      RenamePlaylistArgs(playlistId: playlist.id, newName: name.trim()),
    );
  }

  Future<void> _confirmAndDeleteDialog(
    BuildContext context,
    int playlistId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Playlist?'),
          content: const Text(
            'This will remove the playlist and its verse order. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      di<PlaylistManager>().deletePlaylistCommand.run(playlistId);
    }
  }
}

/// Shared name-entry dialog used for both create and rename flows.
Future<String?> _showNameDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
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
            child: Text(initialValue == null ? 'Create' : 'Save'),
          ),
        ],
      );
    },
  );
}
