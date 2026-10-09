// Behavior based on DenserMeerkat/June (GPL-3.0)

const String peopleTable = 'people';
const String entryPeopleTable = 'entry_people';

class PersonFields {
  static const List<String> values = [
    id,
    name,
    note,
    color,
    timeCreate,
    timeModified,
  ];

  static const String id = 'id';
  static const String name = 'name';
  static const String note = 'note';
  static const String color = 'color';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class EntryPersonFields {
  static const List<String> values = [
    id,
    entryId,
    personId,
  ];

  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String personId = 'person_id';
}

class Person {
  final int? id;
  final String name;
  final String? note;
  final int? color;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Person({
    this.id,
    required this.name,
    this.note,
    this.color,
    required this.timeCreate,
    required this.timeModified,
  });

  Person copy({
    int? id,
    String? name,
    String? note,
    int? color,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Person(
        id: id ?? this.id,
        name: name ?? this.name,
        note: note ?? this.note,
        color: color ?? this.color,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Person fromJson(Map<String, Object?> json) => Person(
        id: json[PersonFields.id] as int?,
        name: json[PersonFields.name] as String,
        note: json[PersonFields.note] as String?,
        color: json[PersonFields.color] as int?,
        timeCreate: DateTime.parse(json[PersonFields.timeCreate] as String),
        timeModified: DateTime.parse(json[PersonFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        PersonFields.id: id,
        PersonFields.name: name,
        PersonFields.note: note,
        PersonFields.color: color,
        PersonFields.timeCreate: timeCreate.toIso8601String(),
        PersonFields.timeModified: timeModified.toIso8601String(),
      };
}

class EntryPerson {
  final int? id;
  final int entryId;
  final int personId;

  const EntryPerson({
    this.id,
    required this.entryId,
    required this.personId,
  });

  EntryPerson copy({
    int? id,
    int? entryId,
    int? personId,
  }) =>
      EntryPerson(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        personId: personId ?? this.personId,
      );

  static EntryPerson fromJson(Map<String, Object?> json) => EntryPerson(
        id: json[EntryPersonFields.id] as int?,
        entryId: json[EntryPersonFields.entryId] as int,
        personId: json[EntryPersonFields.personId] as int,
      );

  Map<String, Object?> toJson() => {
        EntryPersonFields.id: id,
        EntryPersonFields.entryId: entryId,
        EntryPersonFields.personId: personId,
      };
}
