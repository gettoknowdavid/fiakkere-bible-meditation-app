import 'package:objectbox/objectbox.dart';

@Entity()
class Metadata {
  Metadata({
    this.id = 0,
    required this.name,
    required this.shortname,
    required this.module,
    required this.year,
    this.publisher,
    this.owner,
    required this.description,
    required this.lang,
    required this.langShort,
    required this.copyrightStatement,
  });

  @Id()
  int id;

  String name;

  @Index()
  String shortname;

  String module;

  String year;

  String? publisher;

  String? owner;

  String description;

  String lang;

  String langShort;

  String copyrightStatement;
}
