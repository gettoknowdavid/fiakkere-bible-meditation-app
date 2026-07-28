import 'package:objectbox/objectbox.dart';

import 'playlist_item.dart';

@Entity()
class MeditationPlaylist {
  MeditationPlaylist({
    this.id = 0,
    required this.name,
    required this.createdAt,
  });

  @Id()
  int id;

  String name;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  final items = ToMany<PlaylistItem>();
}
