// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/exports/export_json.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:path/path.dart';

const _zipSignature = [0x50, 0x4B, 0x03, 0x04];
const _extractedFolderName = 'archive_contents';

Future<ImportBundle> parseJson(ImportSource source) async {
  final extractedPath = await _extractIfArchive(source);
  final document =
      extractedPath == null ? source.file : _singleJsonDocument(extractedPath);
  final root = json.decode(utf8.decode(await document.readAsBytes()));

  if (root is List) {
    return ImportBundle(
        entries: [for (final entry in root) _parseLegacyEntry(entry)]);
  }
  if (root is Map && root['format'] == jsonFormatMarker) {
    if (root['version'] != jsonFormatVersion) {
      throw FormatException('Unsupported version', root['version']);
    }
    return _parseCurrent(root, extractedPath ?? source.directoryPath);
  }
  throw const FormatException('Not a Daily You JSON file');
}

Future<String?> _extractIfArchive(ImportSource source) async {
  final handle = await source.file.open();
  final List<int> header;
  try {
    header = await handle.read(_zipSignature.length);
  } finally {
    await handle.close();
  }
  if (!_hasZipSignature(header)) return null;

  final extractedPath = join(source.directoryPath, _extractedFolderName);
  await ZipUtils.extract(source.file.path, extractedPath);
  return extractedPath;
}

bool _hasZipSignature(List<int> header) =>
    header.length == _zipSignature.length &&
    [for (final (index, byte) in _zipSignature.indexed) header[index] == byte]
        .every((matches) => matches);

File _singleJsonDocument(String extractedPath) {
  final documents = [
    for (final entity in Directory(extractedPath).listSync())
      if (entity is File && extension(entity.path).toLowerCase() == '.json')
        entity
  ];
  if (documents.length != 1) {
    throw const FormatException('Expected a single JSON document in the zip');
  }
  return documents.single;
}

ImportBundle _parseCurrent(Map root, String contentsPath) {
  return ImportBundle(
    categories: [
      for (final category in root['categories'] as List)
        if (sanitizeTagName(category['name']).isNotEmpty)
          ImportedCategory(
            name: sanitizeTagName(category['name']),
            color: category['color'],
            icon: category['icon'],
            iconType: TagIconType.values.byName(category['iconType']),
          )
    ],
    tagDefinitions: [
      for (final tag in root['tags'] as List)
        if (sanitizeTagName(tag['name']).isNotEmpty)
          ImportedTagDefinition(
            name: sanitizeTagName(tag['name']),
            tagType: TagType.values.byName(tag['type']),
            categoryName: _categoryName(tag['category']),
            color: tag['color'],
            icon: tag['icon'],
            iconType: TagIconType.values.byName(tag['iconType']),
          )
    ],
    entries: [
      for (final entry in root['entries'] as List)
        _parseEntry(entry, contentsPath)
    ],
  );
}

String? _categoryName(String? name) {
  final sanitized = name == null ? '' : sanitizeTagName(name);
  return sanitized.isEmpty ? null : sanitized;
}

ImportedEntry _parseEntry(Map entry, String contentsPath) {
  final mood = entry['mood'] as int?;
  return ImportedEntry(
    Entry(
      text: entry['text'],
      mood: Mood.levels.contains(mood) ? mood : null,
      timeCreate: _parseTime(entry['timeCreate']),
      timeModified: _parseTime(entry['timeModified']),
    ),
    tags: [
      for (final tag in entry['tags'] as List)
        if (_parseEntryTag(tag) case final parsed?) parsed
    ],
    attachments: [
      for (final attachment in entry['attachments'] as List)
        if (_parseAttachment(attachment, contentsPath) case final parsed?)
          parsed
    ],
  );
}

ImportedAttachment? _parseAttachment(Map attachment, String contentsPath) {
  final type = AttachmentType.tryFromValue(attachment['type']);
  final relativePath = attachment['path'] as String;
  final file = File(join(contentsPath, relativePath));
  if (!isWithin(contentsPath, normalize(file.path))) {
    throw FormatException('Attachment path leaves the archive', relativePath);
  }
  if (type == null || !file.existsSync()) return null;

  return ImportedAttachment(
    type: type,
    rank: attachment['rank'],
    timeCreate: _parseTime(attachment['timeCreate']),
    media: FileMedia(file),
  );
}

ImportedEntry _parseLegacyEntry(Map<String, dynamic> entry) {
  final timeCreate = _parseTime(entry['timeCreated']);
  final hasLegacyImage = entry['imgPath'] != null;
  return ImportedEntry(
    Entry(
      text: entry['text'],
      mood: Mood.fromLegacy(entry['mood'] as int?),
      timeCreate: timeCreate,
      timeModified: _parseTime(entry['timeModified']),
    ),
    attachments: [
      if (hasLegacyImage)
        ImportedAttachment(
          type: AttachmentType.image,
          rank: 0,
          timeCreate: timeCreate,
          media: ReferenceMedia(entry['imgPath']),
        ),
      if (entry['images'] != null)
        for (final image in entry['images'])
          ImportedAttachment(
            type: AttachmentType.image,
            rank: (image['imgRank'] as int) + (hasLegacyImage ? 1 : 0),
            timeCreate: _parseTime(image['timeCreated']),
            media: ReferenceMedia(image['imgPath']),
          ),
    ],
  );
}

DateTime _parseTime(String text) {
  final parsed = DateTime.parse(text);
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

ImportedEntryTag? _parseEntryTag(Map tag) {
  final name = sanitizeTagName(tag['name']);
  final tagType = TagType.values.byName(tag['type']);
  final value = tag['value'];
  if (name.isEmpty) return null;
  if (tagType == TagType.label) {
    return ImportedEntryTag(name: name, tagType: tagType);
  }
  if (value is! num || !value.isFinite) return null;
  return ImportedEntryTag(name: name, tagType: tagType, value: '$value');
}
