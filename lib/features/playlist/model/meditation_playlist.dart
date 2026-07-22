import 'package:fiakkere/features/playlist/model/playlist_item.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class MeditationPlaylist {
  @Id()
  int id = 0;

  String name = '';

  @Property(type: PropertyType.date)
  DateTime createdAt = DateTime.now();

  final items = ToMany<PlaylistItem>();
}
