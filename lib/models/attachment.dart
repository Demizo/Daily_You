// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

const String attachmentsTable = 'entry_attachments';

enum AttachmentType {
  image,
  audio,
  video;

  static AttachmentType? tryFromValue(String? value) =>
      AttachmentType.values.where((type) => type.name == value).firstOrNull;

  static AttachmentType fromValue(String value) =>
      tryFromValue(value) ??
      (throw FormatException('Unknown attachment type', value));

  String get folderName => switch (this) {
        image => 'Images',
        audio => 'Audio',
        video => 'Video',
      };

  String get defaultExtension => switch (this) {
        image => '.jpg',
        audio => '.m4a',
        video => '.mp4',
      };

  String get mimePattern => switch (this) {
        image => 'image/*',
        audio => 'audio/*',
        video => 'video/*',
      };

  bool get isVisual => this != audio;

  int? get largeFileWarningBytes => switch (this) {
        image => null,
        audio => 5 * 1024 * 1024,
        video => 20 * 1024 * 1024,
      };

  bool isLarge(int sizeBytes) {
    final threshold = largeFileWarningBytes;
    return threshold != null && sizeBytes > threshold;
  }
}

class EntryAttachmentFields {
  static const List<String> values = [
    id,
    entryId,
    type,
    filePath,
    rank,
    timeCreate,
  ];
  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String type = 'type';
  static const String filePath = 'file_path';
  static const String rank = 'rank';
  static const String timeCreate = 'time_create';
}

class NewAttachment {
  final AttachmentType type;
  final String filePath;

  const NewAttachment({
    required this.type,
    required this.filePath,
  });
}

class EntryAttachment {
  final int? id;
  int? entryId;
  final AttachmentType type;
  final String filePath;
  int rank;
  final DateTime timeCreate;

  EntryAttachment({
    this.id,
    required this.entryId,
    required this.type,
    required this.filePath,
    required this.rank,
    required this.timeCreate,
  });

  EntryAttachment copy({
    int? id,
    int? entryId,
    AttachmentType? type,
    String? filePath,
    int? rank,
    DateTime? timeCreate,
  }) =>
      EntryAttachment(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        type: type ?? this.type,
        filePath: filePath ?? this.filePath,
        rank: rank ?? this.rank,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static List<EntryAttachment> appendRanked(
    List<EntryAttachment> attachments,
    List<NewAttachment> newAttachments, {
    required int? entryId,
  }) {
    final result = [for (final attachment in attachments) attachment.copy()];
    for (final newAttachment in newAttachments) {
      for (final attachment in result) {
        attachment.rank += 1;
      }
      result.add(EntryAttachment(
        entryId: entryId,
        type: newAttachment.type,
        filePath: newAttachment.filePath,
        rank: 0,
        timeCreate: DateTime.now(),
      ));
    }
    return result;
  }

  static EntryAttachment? tryFromJson(Map<String, Object?> json) =>
      AttachmentType.tryFromValue(
                  json[EntryAttachmentFields.type] as String?) ==
              null
          ? null
          : fromJson(json);

  static EntryAttachment fromJson(Map<String, Object?> json) => EntryAttachment(
        id: json[EntryAttachmentFields.id] as int?,
        entryId: json[EntryAttachmentFields.entryId] as int?,
        type: AttachmentType.fromValue(
            json[EntryAttachmentFields.type] as String),
        filePath: json[EntryAttachmentFields.filePath] as String,
        rank: json[EntryAttachmentFields.rank] as int,
        timeCreate:
            DateTime.parse(json[EntryAttachmentFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        EntryAttachmentFields.id: id,
        EntryAttachmentFields.entryId: entryId,
        EntryAttachmentFields.type: type.name,
        EntryAttachmentFields.filePath: filePath,
        EntryAttachmentFields.rank: rank,
        EntryAttachmentFields.timeCreate: timeCreate.toIso8601String(),
      };
}
