import 'package:daily_you/models/tag_icon_type.dart';

const String tagCategoriesTable = 'tag_categories';

class TagCategoryFields {
  static const List<String> values = [
    id,
    name,
    icon,
    iconType,
    color,
    sortOrder,
    timeCreate,
    timeModified,
  ];
  static const String id = 'id';
  static const String name = 'name';
  static const String icon = 'icon';
  static const String iconType = 'icon_type';
  static const String color = 'color';
  static const String sortOrder = 'sort_order';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class TagCategory {
  final int? id;
  final String name;
  final String? icon;
  final TagIconType iconType;
  final int? color;
  final int sortOrder;
  final DateTime timeCreate;
  final DateTime timeModified;

  const TagCategory({
    this.id,
    required this.name,
    this.icon,
    this.iconType = TagIconType.character,
    this.color,
    this.sortOrder = 0,
    required this.timeCreate,
    required this.timeModified,
  });

  TagCategory copy({
    int? id,
    String? name,
    String? icon,
    TagIconType? iconType,
    int? color,
    int? sortOrder,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      TagCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        iconType: iconType ?? this.iconType,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static TagCategory fromJson(Map<String, Object?> json) => TagCategory(
        id: json[TagCategoryFields.id] as int?,
        name: json[TagCategoryFields.name] as String,
        icon: json[TagCategoryFields.icon] as String?,
        iconType:
            TagIconType.fromInt(json[TagCategoryFields.iconType] as int?),
        color: json[TagCategoryFields.color] as int?,
        sortOrder: (json[TagCategoryFields.sortOrder] as int?) ?? 0,
        timeCreate:
            DateTime.parse(json[TagCategoryFields.timeCreate] as String),
        timeModified:
            DateTime.parse(json[TagCategoryFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        TagCategoryFields.id: id,
        TagCategoryFields.name: name,
        TagCategoryFields.icon: icon,
        TagCategoryFields.iconType: iconType.toInt(),
        TagCategoryFields.color: color,
        TagCategoryFields.sortOrder: sortOrder,
        TagCategoryFields.timeCreate: timeCreate.toIso8601String(),
        TagCategoryFields.timeModified: timeModified.toIso8601String(),
      };
}
