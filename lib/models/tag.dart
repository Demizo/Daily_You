const String tagsTable = 'tags';

class TagsFields {
  static const List<String> values = [id, name, timeCreate, timeModified];
  static const String id = 'id';
  static const String name = 'name';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class Tag {
  final int? id;
  final String name;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Tag({
    this.id,
    required this.name,
    required this.timeCreate,
    required this.timeModified,
  });

  Tag copy({
    int? id,
    String? name,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Tag fromJson(Map<String, Object?> json) => Tag(
        id: json[TagsFields.id] as int?,
        name: json[TagsFields.name] as String,
        timeCreate: DateTime.parse(json[TagsFields.timeCreate] as String),
        timeModified:
            DateTime.parse(json[TagsFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        TagsFields.id: id,
        TagsFields.name: name,
        TagsFields.timeCreate: timeCreate.toIso8601String(),
        TagsFields.timeModified: timeModified.toIso8601String(),
      };
}
