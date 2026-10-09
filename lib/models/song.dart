// Behavior based on DenserMeerkat/June (GPL-3.0)

const String entrySongsTable = 'entry_songs';
const String templateSongSlotsTable = 'template_song_slots';

class EntrySongFields {
  static const List<String> values = [
    id,
    entryId,
    videoId,
    url,
    title,
    artist,
    coverPath,
    previewUrl,
    previewStartMs,
    previewEndMs,
    timeCreate,
  ];

  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String videoId = 'video_id';
  static const String url = 'url';
  static const String title = 'title';
  static const String artist = 'artist';
  static const String coverPath = 'cover_path';
  static const String previewUrl = 'preview_url';
  static const String previewStartMs = 'preview_start_ms';
  static const String previewEndMs = 'preview_end_ms';
  static const String timeCreate = 'time_create';
}

class EntrySong {
  final int? id;
  int? entryId;
  final String videoId;
  final String url;
  final String title;
  final String artist;
  final String? coverPath;
  final String? previewUrl;
  final int previewStartMs;
  final int? previewEndMs;
  final DateTime timeCreate;

  EntrySong({
    this.id,
    required this.entryId,
    required this.videoId,
    required this.url,
    required this.title,
    required this.artist,
    this.coverPath,
    this.previewUrl,
    this.previewStartMs = 0,
    this.previewEndMs,
    required this.timeCreate,
  });

  EntrySong copy({
    int? id,
    int? entryId,
    String? videoId,
    String? url,
    String? title,
    String? artist,
    String? coverPath,
    String? previewUrl,
    int? previewStartMs,
    int? previewEndMs,
    DateTime? timeCreate,
  }) =>
      EntrySong(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        videoId: videoId ?? this.videoId,
        url: url ?? this.url,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        coverPath: coverPath ?? this.coverPath,
        previewUrl: previewUrl ?? this.previewUrl,
        previewStartMs: previewStartMs ?? this.previewStartMs,
        previewEndMs: previewEndMs ?? this.previewEndMs,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static EntrySong fromJson(Map<String, Object?> json) => EntrySong(
        id: json[EntrySongFields.id] as int?,
        entryId: json[EntrySongFields.entryId] as int?,
        videoId: json[EntrySongFields.videoId] as String,
        url: json[EntrySongFields.url] as String,
        title: json[EntrySongFields.title] as String,
        artist: json[EntrySongFields.artist] as String,
        coverPath: json[EntrySongFields.coverPath] as String?,
        previewUrl: json[EntrySongFields.previewUrl] as String?,
        previewStartMs: (json[EntrySongFields.previewStartMs] as int?) ?? 0,
        previewEndMs: json[EntrySongFields.previewEndMs] as int?,
        timeCreate: DateTime.parse(json[EntrySongFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        EntrySongFields.id: id,
        EntrySongFields.entryId: entryId,
        EntrySongFields.videoId: videoId,
        EntrySongFields.url: url,
        EntrySongFields.title: title,
        EntrySongFields.artist: artist,
        EntrySongFields.coverPath: coverPath,
        EntrySongFields.previewUrl: previewUrl,
        EntrySongFields.previewStartMs: previewStartMs,
        EntrySongFields.previewEndMs: previewEndMs,
        EntrySongFields.timeCreate: timeCreate.toIso8601String(),
      };
}

class TemplateSongSlotFields {
  static const List<String> values = [id, templateId, timeCreate];
  static const String id = 'id';
  static const String templateId = 'template_id';
  static const String timeCreate = 'time_create';
}

class TemplateSongSlot {
  final int? id;
  final int templateId;
  final DateTime timeCreate;

  const TemplateSongSlot({
    this.id,
    required this.templateId,
    required this.timeCreate,
  });

  TemplateSongSlot copy({
    int? id,
    int? templateId,
    DateTime? timeCreate,
  }) =>
      TemplateSongSlot(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static TemplateSongSlot fromJson(Map<String, Object?> json) =>
      TemplateSongSlot(
        id: json[TemplateSongSlotFields.id] as int?,
        templateId: json[TemplateSongSlotFields.templateId] as int,
        timeCreate:
            DateTime.parse(json[TemplateSongSlotFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        TemplateSongSlotFields.id: id,
        TemplateSongSlotFields.templateId: templateId,
        TemplateSongSlotFields.timeCreate: timeCreate.toIso8601String(),
      };
}
