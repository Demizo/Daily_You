// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

const String attachmentsTable = 'entry_images';

class EntryAttachmentFields {
  static const List<String> values = [id, entryId, filePath, rank, timeCreate];
  static const String id = 'id';
  static const String entryId = 'entry_id';
  static const String filePath = 'img_path';
  static const String rank = 'img_rank';
  static const String timeCreate = 'time_create';
}

class EntryAttachment {
  final int? id;
  int? entryId;
  final String filePath;
  int rank;
  final DateTime timeCreate;

  EntryAttachment({
    this.id,
    required this.entryId,
    required this.filePath,
    required this.rank,
    required this.timeCreate,
  });

  EntryAttachment copy({
    int? id,
    int? entryId,
    String? filePath,
    int? rank,
    DateTime? timeCreate,
  }) =>
      EntryAttachment(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        filePath: filePath ?? this.filePath,
        rank: rank ?? this.rank,
        timeCreate: timeCreate ?? this.timeCreate,
      );

  static List<EntryAttachment> appendRanked(
    List<EntryAttachment> attachments,
    List<String> newFilePaths, {
    required int entryId,
  }) {
    final result = [for (final attachment in attachments) attachment.copy()];
    for (final path in newFilePaths) {
      for (final attachment in result) {
        attachment.rank += 1;
      }
      result.add(EntryAttachment(
        entryId: entryId,
        filePath: path,
        rank: 0,
        timeCreate: DateTime.now(),
      ));
    }
    return result;
  }

  static EntryAttachment fromJson(Map<String, Object?> json) => EntryAttachment(
        id: json[EntryAttachmentFields.id] as int?,
        entryId: json[EntryAttachmentFields.entryId] as int?,
        filePath: json[EntryAttachmentFields.filePath] as String,
        rank: json[EntryAttachmentFields.rank] as int,
        timeCreate:
            DateTime.parse(json[EntryAttachmentFields.timeCreate] as String),
      );

  Map<String, Object?> toJson() => {
        EntryAttachmentFields.id: id,
        EntryAttachmentFields.entryId: entryId,
        EntryAttachmentFields.filePath: filePath,
        EntryAttachmentFields.rank: rank,
        EntryAttachmentFields.timeCreate: timeCreate.toIso8601String(),
      };
}
