// ADR: Verse/CrossReference live in _shared/models because they're read by
// scripture, playlist, and session features (cross-feature = _shared per TRD §6
// promotion rule). MeditationPlaylist/PlaylistItem live in features/playlist/model
// because only the playlist feature owns/mutates them; session only reads via
// PlaylistManager, not directly.

import 'package:fiakkere/_shared/models/cross_reference.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Verse {
  @Id()
  int id = 0;

  @Index()
  String reference = '';

  @Index()
  int book = 0;

  int chapter = 0;

  int verse = 0;

  @Index()
  String text = '';

  String translation = 'WEB';

  @Backlink('sourceVerse')
  final crossReferences = ToMany<CrossReference>();
}
