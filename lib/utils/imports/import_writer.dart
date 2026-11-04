// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/tag_category_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:path/path.dart';

class ImportWriter {
  final Set<DateTime> _entryTimes = {};
  final Map<String, int> _categoryIdByName = {};
  final Map<String, int> _tagIdByKey = {};
  final Map<int?, int> _nextTagOrderByCategory = {};
  final Map<AttachmentType, Set<String>> _takenNamesByType = {};
  int _nextCategoryOrder = 0;

  Future<OperationOutcome> write(
      ImportBundle bundle, void Function(String) updateStatus) async {
    var outcome = const OperationOutcome.succeeded();

    try {
      await _loadExisting();
      for (final category in bundle.categories) {
        await _categoryId(category);
      }
      for (final definition in bundle.tagDefinitions) {
        await _tagId(definition);
      }

      var processedEntries = 0;
      for (final imported in bundle.entries) {
        await _writeEntry(imported);
        processedEntries += 1;
        updateStatus(
            "${((processedEntries / bundle.entries.length) * 100).round()}%");
      }
    } catch (error) {
      outcome = OperationOutcome.failed(error);
    }

    return _finish(outcome, updateStatus);
  }

  Future<void> _loadExisting() async {
    await EntriesProvider.instance.load();
    await EntryAttachmentsProvider.instance.load();
    await TagsProvider.instance.load();

    _entryTimes.addAll(
        EntriesProvider.instance.entries.map((entry) => entry.timeCreate));

    for (final category in TagsProvider.instance.categories) {
      _categoryIdByName.putIfAbsent(
          category.name.toLowerCase(), () => category.id!);
      _nextCategoryOrder = max(_nextCategoryOrder, category.sortOrder + 1);
    }
    for (final tag in TagsProvider.instance.tags) {
      _tagIdByKey.putIfAbsent(_tagKey(tag.tagType, tag.name), () => tag.id!);
      _nextTagOrderByCategory[tag.categoryId] =
          max(_nextTagOrderByCategory[tag.categoryId] ?? 0, tag.sortOrder + 1);
    }
  }

  String _tagKey(TagType tagType, String name) =>
      '${tagType.name}:${name.toLowerCase()}';

  Future<int> _categoryId(ImportedCategory category) async {
    final existingId = _categoryIdByName[category.name.toLowerCase()];
    if (existingId != null) return existingId;

    final now = DateTime.now();
    final added = await TagCategoryDao.add(TagCategory(
      name: category.name,
      icon: category.icon,
      iconType: category.iconType,
      color: category.color,
      sortOrder: _nextCategoryOrder++,
      timeCreate: now,
      timeModified: now,
    ));
    _categoryIdByName[category.name.toLowerCase()] = added.id!;
    return added.id!;
  }

  Future<int> _tagId(ImportedTagDefinition definition) async {
    final key = _tagKey(definition.tagType, definition.name);
    final existingId = _tagIdByKey[key];
    if (existingId != null) return existingId;

    final categoryName = definition.categoryName;
    final categoryId = categoryName == null
        ? null
        : await _categoryId(ImportedCategory(name: categoryName));
    final sortOrder = _nextTagOrderByCategory[categoryId] ?? 0;
    _nextTagOrderByCategory[categoryId] = sortOrder + 1;

    final timeCreate = definition.timeCreate ?? DateTime.now();
    final added = await TagDao.add(Tag(
      categoryId: categoryId,
      name: definition.name,
      tagType: definition.tagType,
      icon: definition.icon,
      iconType: definition.iconType,
      color: definition.color,
      sortOrder: sortOrder,
      timeCreate: timeCreate,
      timeModified: timeCreate,
    ));
    _tagIdByKey[key] = added.id!;
    return added.id!;
  }

  Future<void> _writeEntry(ImportedEntry imported) async {
    if (!_entryTimes.add(imported.entry.timeCreate)) return;

    final added =
        await EntriesProvider.instance.add(imported.entry, skipUpdate: true);

    final addedTagIds = <int>{};
    for (final entryTag in imported.tags) {
      final tagId = await _tagId(ImportedTagDefinition(
          name: entryTag.name, tagType: entryTag.tagType));
      if (!addedTagIds.add(tagId)) continue;
      await EntryTagDao.add(EntryTag(
        entryId: added.id!,
        tagId: tagId,
        value: entryTag.value,
        timeCreate: imported.entry.timeCreate,
      ));
    }

    for (final attachment in imported.attachments) {
      await _writeAttachment(added.id!, attachment);
    }
  }

  Future<void> _writeAttachment(
      int entryId, ImportedAttachment attachment) async {
    final takenNames = _takenNamesByType[attachment.type] ??=
        await AttachmentStorage.instance.takenLowerCaseNames(attachment.type);

    final filePath = switch (attachment.media) {
      BytesMedia(:final bytes) => await AttachmentStorage.instance.create(
          null, bytes, attachment.type,
          currTime: attachment.timeCreate,
          skipExternalUpload: true,
          takenNames: takenNames),
      FileMedia(:final file) => await AttachmentStorage.instance.createFromFile(
          basename(file.path), file, attachment.type,
          currTime: attachment.timeCreate,
          skipExternalUpload: true,
          takenNames: takenNames),
      ReferenceMedia(:final fileName) => fileName,
    };
    if (filePath == null) return;

    await EntryAttachmentsProvider.instance.add(
        EntryAttachment(
          entryId: entryId,
          type: attachment.type,
          filePath: filePath,
          rank: attachment.rank,
          timeCreate: attachment.timeCreate,
        ),
        skipUpdate: true);
  }

  Future<OperationOutcome> _finish(
      OperationOutcome outcome, void Function(String) updateStatus) async {
    await EntriesProvider.instance.load();
    await EntryAttachmentsProvider.instance.load();
    await TagsProvider.instance.load();
    await AppDatabase.instance.updateExternalDatabase();

    if (AttachmentStorage.instance.usingExternalLocation()) {
      try {
        await AttachmentStorage.instance.syncAttachmentFolders(true,
            onProgress: (progress) => updateStatus(progress.counts ?? ''));
      } catch (error) {
        return outcome.failed ? outcome : OperationOutcome.failed(error);
      }
    }
    return outcome;
  }
}
