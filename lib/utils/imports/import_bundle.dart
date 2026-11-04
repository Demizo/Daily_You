// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';

class ImportBundle {
  const ImportBundle({
    this.categories = const [],
    this.tagDefinitions = const [],
    this.entries = const [],
  });

  final List<ImportedCategory> categories;
  final List<ImportedTagDefinition> tagDefinitions;
  final List<ImportedEntry> entries;
}

class ImportedCategory {
  const ImportedCategory({
    required this.name,
    this.color,
    this.icon,
    this.iconType = TagIconType.character,
  });

  final String name;
  final int? color;
  final String? icon;
  final TagIconType iconType;
}

class ImportedTagDefinition {
  const ImportedTagDefinition({
    required this.name,
    required this.tagType,
    this.categoryName,
    this.color,
    this.icon,
    this.iconType = TagIconType.character,
    this.timeCreate,
  });

  final String name;
  final TagType tagType;
  final String? categoryName;
  final int? color;
  final String? icon;
  final TagIconType iconType;
  final DateTime? timeCreate;
}

class ImportedEntryTag {
  const ImportedEntryTag({
    required this.name,
    required this.tagType,
    this.value,
  });

  final String name;
  final TagType tagType;
  final String? value;
}

class ImportedEntry {
  const ImportedEntry(
    this.entry, {
    this.tags = const [],
    this.attachments = const [],
  });

  final Entry entry;
  final List<ImportedEntryTag> tags;
  final List<ImportedAttachment> attachments;
}

class ImportedAttachment {
  const ImportedAttachment({
    required this.type,
    required this.rank,
    required this.timeCreate,
    required this.media,
  });

  final AttachmentType type;
  final int rank;
  final DateTime timeCreate;
  final ImportedMedia media;
}

sealed class ImportedMedia {
  const ImportedMedia();
}

final class BytesMedia extends ImportedMedia {
  const BytesMedia(this.bytes);

  final Uint8List bytes;
}

final class FileMedia extends ImportedMedia {
  const FileMedia(this.file);

  final File file;
}

final class ReferenceMedia extends ImportedMedia {
  const ReferenceMedia(this.fileName);

  final String fileName;
}
