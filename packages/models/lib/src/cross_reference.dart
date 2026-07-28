import 'package:objectbox/objectbox.dart';

import 'verse.dart';

@Entity()
class CrossReference {
  CrossReference({this.id = 0, required this.weight});

  @Id()
  int id;

  int weight;

  final sourceVerse = ToOne<Verse>();

  final relatedVerse = ToOne<Verse>();
}
