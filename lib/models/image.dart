const String imagesTable = 'entry_images';

class EntryImageFields {
  static const List<String> values = [
    id,
    entryId,
    imgPath,
    imgRank,
    timeCreate
  ];
  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String imgPath = 'img_path';
  static const String imgRank = 'img_rank';
  static const String timeCreate = 'time_create';
}

class EntryImage {
  final int? id;
  int? entryId;
  final String imgPath;
  int imgRank;
  final DateTime timeCreate;

  EntryImage({
    this.id,
    required this.entryId,
    required this.imgPath,
    required this.imgRank,
    required this.timeCreate,
  });

  EntryImage copy({
    int? id,
    int? entryId,
    String? imgPath,
    int? imgRank,
    DateTime? timeCreate,
  }) =>
      EntryImage(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        imgPath: imgPath ?? this.imgPath,
        imgRank: imgRank ?? this.imgRank,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static EntryImage fromJson(Map<String, Object?> json) => EntryImage(
        id: json[EntryImageFields.id] as int?,
        entryId: json[EntryImageFields.entryId] as int?,
        imgPath: json[EntryImageFields.imgPath] as String,
        imgRank: json[EntryImageFields.imgRank] as int,
        timeCreate: DateTime.parse(json[EntryImageFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        EntryImageFields.id: id,
        EntryImageFields.entryId: entryId,
        EntryImageFields.imgPath: imgPath,
        EntryImageFields.imgRank: imgRank,
        EntryImageFields.timeCreate: timeCreate.toIso8601String(),
      };
}
