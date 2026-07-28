import 'package:objectbox/objectbox.dart';

import 'meditation_playlist.dart';
import 'verse.dart';

@Entity()
class PlaylistItem {
  PlaylistItem({this.id = 0, this.sortOrder = 0});

  @Id()
  int id;

  int sortOrder;

  final playlist = ToOne<MeditationPlaylist>();

  final verse = ToOne<Verse>();
}
