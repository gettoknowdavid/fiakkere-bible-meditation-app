import 'package:fiakkere/_shared/models/verse.dart';
import 'package:fiakkere/features/playlist/model/meditation_playlist.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class PlaylistItem {
  @Id()
  int id = 0;

  final playlist = ToOne<MeditationPlaylist>();

  final verse = ToOne<Verse>();

  int sortOrder = 0;
}
