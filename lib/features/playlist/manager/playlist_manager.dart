import 'dart:async';

import 'package:fiakkere/_shared/services/database_service.dart';
import 'package:flutter_it/flutter_it.dart';
import 'package:models/models.dart';

class PlaylistManager implements Disposable {
  PlaylistManager(this._database) {
    _initPlaylistStream();

    createPlaylistCommand = Command.createSync(
      _createPlaylist,
      initialValue: null,
    );
    deletePlaylistCommand = Command.createSyncNoResult(_deletePlaylist);
    renamePlaylistCommand = Command.createSyncNoResult(_renamePlaylist);
    addVerseCommand = Command.createSyncNoResult(_addVerse);
    removeVerseCommand = Command.createSyncNoResult(_removeVerse);
    reorderCommand = Command.createSyncNoResult(_reorder);
    loadPlaylistItemsCommand = Command.createSyncNoResult(_loadItems);
  }

  final Database _database;

  late final Command<String, MeditationPlaylist?> createPlaylistCommand;
  late final Command<int, void> deletePlaylistCommand;
  late final Command<RenamePlaylistArgs, void> renamePlaylistCommand;
  late final Command<AddVerseArgs, void> addVerseCommand;
  late final Command<int, void> removeVerseCommand;
  late final Command<ReorderArgs, void> reorderCommand;
  late final Command<int, void> loadPlaylistItemsCommand;

  // late final Stream<Query<MeditationPlaylist>> _playlistQueryStream;
  late final StreamSubscription _playlistSubscription;

  final playlists = ListNotifier<MeditationPlaylist>(data: []);
  final activeItems = ListNotifier<PlaylistItem>(data: []);

  Store get _store => _database.store;

  Box<MeditationPlaylist> get _playlistBox => _store.box<MeditationPlaylist>();

  Box<PlaylistItem> get _itemBox => _store.box<PlaylistItem>();

  Box<Verse> get _verseBox => _store.box<Verse>();

  void _initPlaylistStream() {
    final query = _playlistBox.query().order(
      MeditationPlaylist_.createdAt,
      flags: Order.descending,
    );
    _playlistSubscription = query.watch(triggerImmediately: true).listen((q) {
      playlists.startTransAction();
      playlists.clear();
      playlists.addAll(q.find());
      playlists.endTransAction();
    });
  }

  MeditationPlaylist _createPlaylist(String name) {
    final sanitizedName = name.trim();
    if (sanitizedName.isEmpty) throw ArgumentError("Name cannot be empty");
    final entity = MeditationPlaylist(name: name, createdAt: DateTime.now());
    _playlistBox.put(entity);
    return entity;
  }

  void _deletePlaylist(int playlistId) {
    final itemQuery = _itemBox
        .query(PlaylistItem_.playlist.equals(playlistId))
        .build();
    try {
      final itemsToRemove = itemQuery.find();
      _itemBox.removeMany(itemsToRemove.map((i) => i.id).toList());
    } finally {
      itemQuery.close();
      _playlistBox.remove(playlistId);
    }
  }

  void _renamePlaylist(RenamePlaylistArgs args) {
    final playlist = _playlistBox.get(args.playlistId);
    if (playlist == null) throw StateError("Playlist not found");
    playlist.name = args.newName;
    _playlistBox.put(playlist);
  }

  void _loadItems(int playlistId) {
    final query = _itemBox
        .query(PlaylistItem_.playlist.equals(playlistId))
        .order(PlaylistItem_.sortOrder)
        .build();
    try {
      final result = query.find();
      activeItems.startTransAction();
      activeItems.clear();
      activeItems.addAll(result);
      activeItems.endTransAction();
    } finally {
      query.close();
    }
  }

  void _addVerse(AddVerseArgs args) {
    late int nextOrder;

    final maxOrderQuery = _itemBox
        .query(PlaylistItem_.playlist.equals(args.playlistId))
        .order(PlaylistItem_.sortOrder, flags: Order.descending)
        .build();

    try {
      final existing = maxOrderQuery.findFirst();
      nextOrder = (existing?.sortOrder ?? -1) + 1;
    } finally {
      maxOrderQuery.close();
    }

    final playlistRef = _playlistBox.get(args.playlistId);
    final verseRef = _verseBox.get(args.verseId);

    if (playlistRef == null || verseRef == null) {
      throw StateError('Invalid playlist/verse id');
    }

    final newItem = PlaylistItem(sortOrder: nextOrder)
      ..playlist.target = playlistRef
      ..verse.target = verseRef;
    _itemBox.put(newItem);

    if (activeItems.any((p) => p.playlist.target?.id == args.playlistId)) {
      _loadItems(args.playlistId);
    }
  }

  void _removeVerse(int playlistItemId) {
    final item = _itemBox.get(playlistItemId);
    if (item == null) return;
    final playlistId = item.playlist.targetId;
    _itemBox.remove(playlistItemId);
    _loadItems(playlistId);
  }

  void _reorder(ReorderArgs args) {
    final query = _itemBox
        .query(PlaylistItem_.playlist.equals(args.playlistId))
        .order(PlaylistItem_.sortOrder)
        .build();
    final items = query.find();
    query.close();
    final moved = items.removeAt(args.oldIndex);
    final adjustedNewIndex = args.newIndex > args.oldIndex
        ? args.newIndex - 1
        : args.newIndex;
    items.insert(adjustedNewIndex, moved);

    for (int i = 0; i < items.length; i++) {
      items[i].sortOrder = i;
    }

    _itemBox.putMany(items);
    _loadItems(args.playlistId);
  }

  @override
  FutureOr<dynamic> onDispose() async {
    await _playlistSubscription.cancel();

    createPlaylistCommand.dispose();
    deletePlaylistCommand.dispose();
    renamePlaylistCommand.dispose();
    addVerseCommand.dispose();
    removeVerseCommand.dispose();
    reorderCommand.dispose();
  }
}

final class RenamePlaylistArgs {
  const RenamePlaylistArgs({required this.playlistId, required this.newName});

  final int playlistId;
  final String newName;
}

final class AddVerseArgs {
  const AddVerseArgs({required this.playlistId, required this.verseId});

  final int playlistId;
  final int verseId;
}

final class ReorderArgs {
  const ReorderArgs({
    required this.playlistId,
    required this.oldIndex,
    required this.newIndex,
  });

  final int playlistId;
  final int oldIndex;
  final int newIndex;
}
