const String entriesTable = 'entries';

class EntryFields {
  static const List<String> values = [
    id,
    text,
    imgPath,
    mood,
    timeCreate,
    timeModified
  ];
  static const String id = 'id';
  static const String text = 'text';
  static const String imgPath = 'img_path';
  static const String mood = 'mood';
  static const String timeCreate = 'time_create';
  static const String timeModified = 'time_modified';
}

class Entry {
  final int? id;
  final String text;
  final String? imgPath;
  final int? mood;
  final DateTime timeCreate;
  final DateTime timeModified;

  const Entry({
    this.id,
    required this.text,
    this.imgPath,
    this.mood,
    required this.timeCreate,
    required this.timeModified,
  });

  Entry copy({
    int? id,
    String? text,
    String? imgPath,
    int? mood,
    DateTime? timeCreate,
    DateTime? timeModified,
  }) =>
      Entry(
        id: id ?? this.id,
        text: text ?? this.text,
        imgPath: imgPath,
        mood: mood,
        timeCreate: timeCreate ?? this.timeCreate,
        timeModified: timeModified ?? this.timeModified,
      );

  static Entry fromJson(Map<String, Object?> json) => Entry(
        id: json[EntryFields.id] as int?,
        text: json[EntryFields.text] as String,
        imgPath: json[EntryFields.imgPath] as String?,
        mood: json[EntryFields.mood] as int?,
        timeCreate: DateTime.parse(json[EntryFields.timeCreate] as String),
        timeModified: DateTime.parse(json[EntryFields.timeModified] as String),
      );

  Map<String, Object?> toJson() => {
        EntryFields.id: id,
        EntryFields.text: text,
        EntryFields.imgPath: imgPath,
        EntryFields.mood: mood,
        EntryFields.timeCreate: timeCreate.toIso8601String(),
        EntryFields.timeModified: timeModified.toIso8601String(),
      };
}
