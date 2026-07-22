import 'package:daily_you/models/tag_icon_type.dart';

const String tagsTable = 'tags';
const String entryTagsTable = 'entry_tags';

enum TagType {
  label,
  tracker;

  int toInt() => index;

  static TagType fromInt(int value) => TagType.values[value];
}

class TagFields {
  static const List<String> values = [
    id,
    categoryId,
    icon,
    iconType,
    name,
    tagType,
    color,
    sortOrder,
    timeCreate,
    timeModified,
  ];
  static const String id = 'id';
  static const String categoryId = 'category_id';
  static const String icon = 'icon';
  static const String iconType = 'icon_type';
  static const String name = 'name';
  static const String tagType = 'tag_type';
  static const String color = 'color';
  static const String sortOrder = 'sort_order';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class Tag {
  final int? id;
  final int? categoryId;
  final String? icon;
  final TagIconType iconType;
  final String name;
  final TagType tagType;
  final int? color;
  final int sortOrder;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Tag({
    this.id,
    this.categoryId,
    this.icon,
    this.iconType = TagIconType.character,
    required this.name,
    required this.tagType,
    this.color,
    this.sortOrder = 0,
    required this.timeCreate,
    required this.timeModified,
  });

  Tag copy({
    int? id,
    int? categoryId,
    String? icon,
    TagIconType? iconType,
    String? name,
    TagType? tagType,
    int? color,
    int? sortOrder,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Tag(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        icon: icon ?? this.icon,
        iconType: iconType ?? this.iconType,
        name: name ?? this.name,
        tagType: tagType ?? this.tagType,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Tag fromJson(Map<String, Object?> json) => Tag(
        id: json[TagFields.id] as int?,
        categoryId: json[TagFields.categoryId] as int?,
        icon: json[TagFields.icon] as String?,
        iconType: TagIconType.fromInt(json[TagFields.iconType] as int?),
        name: json[TagFields.name] as String,
        tagType: TagType.fromInt(json[TagFields.tagType] as int),
        color: json[TagFields.color] as int?,
        sortOrder: (json[TagFields.sortOrder] as int?) ?? 0,
        timeCreate: DateTime.parse(json[TagFields.timeCreate] as String),
        timeModified: DateTime.parse(json[TagFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        TagFields.id: id,
        TagFields.categoryId: categoryId,
        TagFields.icon: icon,
        TagFields.iconType: iconType.toInt(),
        TagFields.name: name,
        TagFields.tagType: tagType.toInt(),
        TagFields.color: color,
        TagFields.sortOrder: sortOrder,
        TagFields.timeCreate: timeCreate.toIso8601String(),
        TagFields.timeModified: timeModified.toIso8601String(),
      };
}

class EntryTagFields {
  static const List<String> values = [id, entryId, tagId, value, timeCreate];
  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String tagId = 'tag_id';
  static const String value = 'value';
  static const String timeCreate = 'time_create';
}

class EntryTag {
  final int? id;
  final int entryId;
  final int tagId;
  final String? value;
  final DateTime timeCreate;

  const EntryTag({
    this.id,
    required this.entryId,
    required this.tagId,
    this.value,
    required this.timeCreate,
  });

  EntryTag copy({
    int? id,
    int? entryId,
    int? tagId,
    String? value,
    DateTime? timeCreate,
  }) =>
      EntryTag(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        tagId: tagId ?? this.tagId,
        value: value ?? this.value,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static EntryTag fromJson(Map<String, Object?> json) => EntryTag(
        id: json[EntryTagFields.id] as int?,
        entryId: json[EntryTagFields.entryId] as int,
        tagId: json[EntryTagFields.tagId] as int,
        value: json[EntryTagFields.value] as String?,
        timeCreate: DateTime.parse(json[EntryTagFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        EntryTagFields.id: id,
        EntryTagFields.entryId: entryId,
        EntryTagFields.tagId: tagId,
        EntryTagFields.value: value,
        EntryTagFields.timeCreate: timeCreate.toIso8601String(),
      };
}
