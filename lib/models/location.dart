// Behavior based on DenserMeerkat/June (GPL-3.0)

const String entryLocationsTable = 'entry_locations';

class EntryLocationFields {
  static const List<String> values = [
    id,
    entryId,
    latitude,
    longitude,
    placeName,
    timeCreate,
  ];

  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String placeName = 'place_name';
  static const String timeCreate = 'time_create';
}

class EntryLocation {
  final int? id;
  int? entryId;
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final DateTime timeCreate;

  EntryLocation({
    this.id,
    required this.entryId,
    this.latitude,
    this.longitude,
    this.placeName,
    required this.timeCreate,
  });

  EntryLocation copy({
    int? id,
    int? entryId,
    double? latitude,
    double? longitude,
    String? placeName,
    DateTime? timeCreate,
  }) =>
      EntryLocation(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        placeName: placeName ?? this.placeName,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static EntryLocation fromJson(Map<String, Object?> json) => EntryLocation(
        id: json[EntryLocationFields.id] as int?,
        entryId: json[EntryLocationFields.entryId] as int?,
        latitude: (json[EntryLocationFields.latitude] as num?)?.toDouble(),
        longitude: (json[EntryLocationFields.longitude] as num?)?.toDouble(),
        placeName: json[EntryLocationFields.placeName] as String?,
        timeCreate:
            DateTime.parse(json[EntryLocationFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        EntryLocationFields.id: id,
        EntryLocationFields.entryId: entryId,
        EntryLocationFields.latitude: latitude,
        EntryLocationFields.longitude: longitude,
        EntryLocationFields.placeName: placeName,
        EntryLocationFields.timeCreate: timeCreate.toIso8601String(),
      };
}
