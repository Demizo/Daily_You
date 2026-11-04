// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/tag_name_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join, relative;

const _fixturesRoot = 'test/fixtures/imports';
const _inputFolderName = 'input';
const _expectedFileName = 'expected.json';

Directory fixtureInputDirectory(ImportFormat format) =>
    Directory(join(_fixturesRoot, format.name, _inputFolderName));

Future<ImportBundle> parseFixture(ImportFormat format) async {
  final option = ImportRegistry.instance.optionFor(format);
  final inputDirectory = fixtureInputDirectory(format);
  final fileName = switch (option.kind) {
    ImportSourceKind.file =>
      basename(inputDirectory.listSync().whereType<File>().single.path),
    ImportSourceKind.archive => 'fixture.zip',
  };
  return option.parse(ImportSource(inputDirectory.path, fileName));
}

Future<void> expectMatchesExpectedBundle(
    ImportFormat format, ImportBundle bundle,
    {Directory? inputDirectory}) async {
  final expectedFile =
      File(join(_fixturesRoot, format.name, _expectedFileName));
  final actual =
      '${const JsonEncoder.withIndent('  ').convert(_bundleToJson(bundle, inputDirectory ?? fixtureInputDirectory(format)))}\n';

  if (Platform.environment['UPDATE_GOLDENS'] == '1') {
    await expectedFile.writeAsString(actual);
    return;
  }
  expect(actual, equals(await expectedFile.readAsString()));
}

void expectValidBundle(ImportBundle bundle) {
  for (final category in bundle.categories) {
    expect(sanitizeTagName(category.name), category.name,
        reason: 'category ${category.name}');
    expect(category.name, isNotEmpty);
  }
  for (final definition in bundle.tagDefinitions) {
    expect(sanitizeTagName(definition.name), definition.name,
        reason: 'tag ${definition.name}');
    expect(definition.name, isNotEmpty);
    final categoryName = definition.categoryName;
    if (categoryName != null) {
      expect(sanitizeTagName(categoryName), categoryName);
    }
  }
  for (final imported in bundle.entries) {
    final entry = imported.entry;
    final reason = 'entry at ${entry.timeCreate}';
    expect(entry.id, isNull, reason: reason);
    expect(entry.mood == null || Mood.levels.contains(entry.mood), isTrue,
        reason: reason);
    expect(entry.timeCreate.isUtc, isFalse, reason: reason);
    expect(entry.timeModified.isUtc, isFalse, reason: reason);

    for (final tag in imported.tags) {
      expect(sanitizeTagName(tag.name), tag.name, reason: reason);
      expect(tag.name, isNotEmpty, reason: reason);
      if (tag.tagType == TagType.tracker) {
        expect(double.tryParse(tag.value ?? '')?.isFinite, isTrue,
            reason: '$reason tracker ${tag.name}');
      } else {
        expect(tag.value, isNull, reason: reason);
      }
    }

    final ranks = imported.attachments.map((attachment) => attachment.rank);
    expect(ranks.every((rank) => rank >= 0), isTrue, reason: reason);
    expect(ranks.toSet(), hasLength(ranks.length), reason: reason);
    for (final attachment in imported.attachments) {
      expect(attachment.timeCreate.isUtc, isFalse, reason: reason);
    }
  }
}

Map<String, Object?> _bundleToJson(
    ImportBundle bundle, Directory inputDirectory) {
  return {
    'categories': [
      for (final category in bundle.categories)
        {
          'name': category.name,
          'color': category.color,
          'icon': category.icon,
          'iconType': category.iconType.name,
        }
    ],
    'tagDefinitions': [
      for (final definition in bundle.tagDefinitions)
        {
          'name': definition.name,
          'type': definition.tagType.name,
          'categoryName': definition.categoryName,
          'color': definition.color,
          'icon': definition.icon,
          'iconType': definition.iconType.name,
          'timeCreate': definition.timeCreate?.toIso8601String(),
        }
    ],
    'entries': [
      for (final imported in bundle.entries)
        {
          'text': imported.entry.text,
          'mood': imported.entry.mood,
          'timeCreate': imported.entry.timeCreate.toIso8601String(),
          'timeModified': imported.entry.timeModified.toIso8601String(),
          'tags': [
            for (final tag in imported.tags)
              {'name': tag.name, 'type': tag.tagType.name, 'value': tag.value}
          ],
          'attachments': [
            for (final attachment in imported.attachments)
              {
                'type': attachment.type.name,
                'rank': attachment.rank,
                'timeCreate': attachment.timeCreate.toIso8601String(),
                'media': switch (attachment.media) {
                  BytesMedia(:final bytes) => {'bytes': base64.encode(bytes)},
                  FileMedia(:final file) => {
                      'file': relative(file.path, from: inputDirectory.path)
                    },
                  ReferenceMedia(:final fileName) => {'reference': fileName},
                },
              }
          ],
        }
    ],
  };
}
