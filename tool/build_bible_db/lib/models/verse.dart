import 'package:objectbox/objectbox.dart';

import 'cross_reference.dart';

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
