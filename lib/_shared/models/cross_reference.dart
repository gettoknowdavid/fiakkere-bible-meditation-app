// ADR: Verse/CrossReference live in _shared/models because they're read by
// scripture, playlist, and session features (cross-feature = _shared per TRD §6
// promotion rule). MeditationPlaylist/PlaylistItem live in features/playlist/model
// because only the playlist feature owns/mutates them; session only reads via
// PlaylistManager, not directly.

import 'package:fiakkere/_shared/models/verse.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class CrossReference {
  @Id()
  int id = 0;

  final sourceVerse = ToOne<Verse>();

  final relatedVerse = ToOne<Verse>();

  int weight = 0;
}
