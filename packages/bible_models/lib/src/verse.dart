import 'package:bible_models/bible_models.dart';

class Verse {
  const Verse({
    required this.id,
    required this.reference,
    required this.universalKey,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.translation = 'WEB',
    this.crossReferences = const [],
  });

  final int id;
  final String reference;
  final String universalKey;
  final int book;
  final int chapter;
  final int verse;
  final String text;
  final String translation;

  final List<CrossReference> crossReferences;

  factory Verse.fromJson(Map<String, dynamic> json) {
    final b = json['book'] as int;
    final c = json['chapter'] as int;
    final v = json['verse'] as int;
    return Verse(
      id: json['id'] as int,
      book: b,
      chapter: c,
      verse: v,
      text: json['text'] as String,
      translation: json['translation'] ?? 'WEB',
      reference: "${json['book_name']} $c:$v",
      universalKey: '$b:$c:$v',
    );
  }

  factory Verse.fromMap(
    Map<String, dynamic> map, {
    List<CrossReference>? crossReferences,
  }) {
    return Verse(
      id: map['id'] as int,
      reference: map['reference'] as String,
      universalKey: map['universalKey'] as String,
      book: map['book'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      text: map['text'] as String,
      translation: map['translation'] as String,
      crossReferences: crossReferences ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'universalKey': universalKey,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'translation': translation,
    };
  }
}
