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
      appBar: AppBar(title: Text('Meditation Playlists')),
      body: _PlaylistList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) {
    return showAdaptiveDialog(
      context: context,
      builder: (context) => SimpleDialog(),
    );
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
      return Center(
        child: Text('No playlists yet — create one to get started'),
      );
    }

    return ListView.separated(
      itemCount: playlists.length,
      itemBuilder: (ctx, i) => _PlaylistRow(playlist: playlists[i]),
      separatorBuilder: (context, index) => SizedBox(height: 10),
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
      trailing: PopupMenuButton(
        itemBuilder: (context) {
          return [
            const PopupMenuItem<String>(value: 'Rename', child: Text('Rename')),
            const PopupMenuItem<String>(value: 'Delete', child: Text('Delete')),
          ];
        },
        onSelected: (action) => switch (action) {
          'Rename' => _showRenameDialog(context, playlist),
          'Delete' => _confirmAndDeleteDialog(context, playlist.id),
          _ => () {},
        },
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    MeditationPlaylist playlist,
  ) {
    return showAdaptiveDialog(
      context: context,
      builder: (context) => SimpleDialog(),
    );
  }

  Future<void> _confirmAndDeleteDialog(BuildContext context, int playlistId) {
    return showAdaptiveDialog(
      context: context,
      builder: (context) => SimpleDialog(),
    );
  }
}
