import 'package:fiakkere/features/playlist/manager/playlist_manager.dart';
import 'package:fiakkere/features/playlist/widgets/playlist_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:models/models.dart';

class PlaylistDetailPage extends WatchingWidget {
  const PlaylistDetailPage({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    final manager = di<PlaylistManager>();
    callOnce((context) => manager.loadPlaylistItemsCommand.run(id));
    return Scaffold(
      appBar: AppBar(title: _PlaylistTitle(playlistId: id)),
      body: _ReorderableItemList(playlistId: id),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}

class _PlaylistTitle extends WatchingWidget {
  const _PlaylistTitle({required this.playlistId});

  final int playlistId;

  @override
  Widget build(BuildContext context) {
    final playlists = watchValue<PlaylistManager, List<MeditationPlaylist>>(
      (m) => m.playlists,
    );
    final playlist = playlists.firstWhere((m) => m.id == playlistId);
    return Text(playlist.name);
  }
}

class _ReorderableItemList extends WatchingWidget {
  const _ReorderableItemList({required this.playlistId});

  final int playlistId;

  @override
  Widget build(BuildContext context) {
    final manager = di<PlaylistManager>();
    final items = watchValue<PlaylistManager, List<PlaylistItem>>(
      (m) => m.activeItems,
    );

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text('No verses in this playlist yet'),
            const SizedBox(height: 10),
            FilledButton(onPressed: () {}, child: Text('Add verses')),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) => PlaylistItemTile(
        // Index within *this build's* item list — required so the drag
        // handle reports the correct source position to onReorder.
        index: i,
        item: items[i],
        onRemove: () => manager.removeVerseCommand.run(items[i].id),
      ),
      onReorderItem: (oldIndex, newIndex) {
        manager.reorderCommand.run(
          ReorderArgs(
            playlistId: playlistId,
            oldIndex: oldIndex,
            newIndex: newIndex,
          ),
        );
      },
    );
  }
}
