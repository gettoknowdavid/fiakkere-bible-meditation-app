import 'package:objectbox/objectbox.dart';

import 'verse.dart';

@Entity()
class CrossReference {
  @Id()
  int id = 0;

  final sourceVerse = ToOne<Verse>();

  final relatedVerse = ToOne<Verse>();

  int weight = 0;
}
