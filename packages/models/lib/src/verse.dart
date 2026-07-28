import 'package:objectbox/objectbox.dart';

import 'cross_reference.dart';
import 'metadata.dart';

@Entity()
class Verse {
  Verse({
    this.id = 0,
    required this.reference,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.translation = 'WEB',
  });

  @Id()
  int id;

  @Index()
  String reference;

  @Index()
  int book;

  int chapter;

  int verse;

  String text;

  String translation;

  final metadata = ToOne<Metadata>();

  @Backlink('sourceVerse')
  final references = ToMany<CrossReference>();
}
