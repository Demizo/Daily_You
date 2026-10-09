// Behavior based on DenserMeerkat/June (GPL-3.0)

const String spacesTable = 'spaces';
const String entrySpacesTable = 'entry_spaces';

class SpaceFields {
  static const List<String> values = [
    id,
    name,
    isDefault,
    icon,
    color,
    timeCreate,
    timeModified,
  ];

  static const String id = 'id';
  static const String name = 'name';
  static const String isDefault = 'is_default';
  static const String icon = 'icon';
  static const String color = 'color';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class EntrySpaceFields {
  static const List<String> values = [
    id,
    entryId,
    spaceId,
  ];

  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String spaceId = 'space_id';
}

class Space {
  final int? id;
  final String name;
  final bool isDefault;
  final String? icon;
  final int? color;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Space({
    this.id,
    required this.name,
    this.isDefault = false,
    this.icon,
    this.color,
    required this.timeCreate,
    required this.timeModified,
  });

  Space copy({
    int? id,
    String? name,
    bool? isDefault,
    String? icon,
    int? color,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Space(
        id: id ?? this.id,
        name: name ?? this.name,
        isDefault: isDefault ?? this.isDefault,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Space fromJson(Map<String, Object?> json) => Space(
        id: json[SpaceFields.id] as int?,
        name: json[SpaceFields.name] as String,
        isDefault: ((json[SpaceFields.isDefault] as int?) ?? 0) == 1,
        icon: json[SpaceFields.icon] as String?,
        color: json[SpaceFields.color] as int?,
        timeCreate: DateTime.parse(json[SpaceFields.timeCreate] as String),
        timeModified: DateTime.parse(json[SpaceFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        SpaceFields.id: id,
        SpaceFields.name: name,
        SpaceFields.isDefault: isDefault ? 1 : 0,
        SpaceFields.icon: icon,
        SpaceFields.color: color,
        SpaceFields.timeCreate: timeCreate.toIso8601String(),
        SpaceFields.timeModified: timeModified.toIso8601String(),
      };
}

class EntrySpace {
  final int? id;
  final int entryId;
  final int spaceId;

  const EntrySpace({
    this.id,
    required this.entryId,
    required this.spaceId,
  });

  EntrySpace copy({
    int? id,
    int? entryId,
    int? spaceId,
  }) =>
      EntrySpace(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        spaceId: spaceId ?? this.spaceId,
      );

  static EntrySpace fromJson(Map<String, Object?> json) => EntrySpace(
        id: json[EntrySpaceFields.id] as int?,
        entryId: json[EntrySpaceFields.entryId] as int,
        spaceId: json[EntrySpaceFields.spaceId] as int,
      );

  Map<String, Object?> toJson() => {
        EntrySpaceFields.id: id,
        EntrySpaceFields.entryId: entryId,
        EntrySpaceFields.spaceId: spaceId,
      };
}
