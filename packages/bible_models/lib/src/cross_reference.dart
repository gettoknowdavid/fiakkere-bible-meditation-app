import 'package:bible_models/bible_models.dart';

class CrossReference {
  const CrossReference({
    this.id,
    required this.sourceVerseId,
    required this.relatedVerseId,
    required this.weight,
    this.sourceVerse,
    this.relatedVerse,
  });

  final int? id;
  final int sourceVerseId;
  final int relatedVerseId;
  final int weight;

  final Verse? sourceVerse;
  final Verse? relatedVerse;

  factory CrossReference.fromMap(
    Map<String, dynamic> map, {
    Verse? sourceVerse,
    Verse? relatedVerse,
  }) {
    return CrossReference(
      id: map['id'] as int,
      sourceVerseId: map['sourceVerseId'] as int,
      relatedVerseId: map['relatedVerseId'] as int,
      weight: map['weight'] as int,
      sourceVerse: sourceVerse,
      relatedVerse: relatedVerse,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sourceVerseId': sourceVerseId,
      'relatedVerseId': relatedVerseId,
      'weight': weight,
    };
  }
}
