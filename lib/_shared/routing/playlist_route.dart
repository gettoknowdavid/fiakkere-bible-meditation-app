import 'package:kaisel/kaisel.dart';

sealed class PlaylistRoute extends KaiselRoute {
  const PlaylistRoute();
}

final class PlaylistList extends PlaylistRoute {
  const PlaylistList();
}

final class PlaylistDetail extends PlaylistRoute {
  const PlaylistDetail(this.playlistId);

  final int playlistId;

  @override
  List<Object?> get props => [playlistId];
}