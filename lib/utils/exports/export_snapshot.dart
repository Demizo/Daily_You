// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';

class ExportSnapshot {
  const ExportSnapshot({
    required this.locale,
    required this.exportedAt,
    required this.moodLabelOf,
    this.moodScale = const [],
    this.categories = const [],
    this.tagDefinitions = const [],
    this.entries = const [],
  });

  final String locale;
  final DateTime exportedAt;
  final String Function(int mood) moodLabelOf;
  final List<MoodScaleLevel> moodScale;
  final List<ExportCategory> categories;
  final List<ExportTagDefinition> tagDefinitions;
  final List<ExportEntry> entries;

  MoodScaleLevel? levelOf(int mood) =>
      moodScale.where((level) => level.mood == mood).firstOrNull;
}

class ExportCategory {
  const ExportCategory({
    required this.name,
    this.icon,
    this.iconType = TagIconType.character,
    this.color,
    this.sortOrder = 0,
  });

  final String name;
  final String? icon;
  final TagIconType iconType;
  final int? color;
  final int sortOrder;
}

class ExportTagDefinition {
  const ExportTagDefinition({
    required this.name,
    required this.tagType,
    this.categoryName,
    this.icon,
    this.iconType = TagIconType.character,
    this.color,
    this.sortOrder = 0,
  });

  final String name;
  final TagType tagType;
  final String? categoryName;
  final String? icon;
  final TagIconType iconType;
  final int? color;
  final int sortOrder;
}

class ExportEntryTag {
  const ExportEntryTag({
    required this.name,
    required this.tagType,
    this.categoryName,
    this.value,
  });

  final String name;
  final TagType tagType;
  final String? categoryName;
  final num? value;
}

class ExportAttachment {
  const ExportAttachment({
    required this.type,
    required this.rank,
    required this.timeCreate,
    required this.sourcePath,
  });

  final AttachmentType type;
  final int rank;
  final DateTime timeCreate;
  final String sourcePath;
}

class ExportEntry {
  const ExportEntry(
    this.entry, {
    this.tags = const [],
    this.attachments = const [],
  });

  final Entry entry;
  final List<ExportEntryTag> tags;
  final List<ExportAttachment> attachments;
}

Future<ExportSnapshot> buildExportSnapshot({
  required AppLocalizations localizations,
  required String locale,
  required Set<AttachmentType> includedTypes,
  void Function(double fraction)? onProgress,
}) async {
  final tagsProvider = TagsProvider.instance;
  final moodScaleProvider = MoodScaleProvider.instance;

  final categoryNameById = {
    for (final category in tagsProvider.categories) category.id: category.name
  };
  final tagById = {for (final tag in tagsProvider.tags) tag.id: tag};
  final tagPositionById = {
    for (final (position, tag) in tagsProvider.tags.indexed) tag.id: position
  };

  final attachmentsByEntryId = <int, List<EntryAttachment>>{};
  for (final attachment in EntryAttachmentsProvider.instance.attachments) {
    final entryId = attachment.entryId;
    if (entryId == null || !includedTypes.contains(attachment.type)) continue;
    (attachmentsByEntryId[entryId] ??= []).add(attachment);
  }

  final sortedEntries = [...EntriesProvider.instance.entries]
    ..sort(_byTimeThenId);

  final entries = <ExportEntry>[];
  for (final entry in sortedEntries) {
    final entryTags = [...tagsProvider.getEntryTagsForEntry(entry.id!)]..sort(
        (first, second) => (tagPositionById[first.tagId] ?? 0)
            .compareTo(tagPositionById[second.tagId] ?? 0));
    final attachments = [...?attachmentsByEntryId[entry.id!]]
      ..sort((first, second) => second.rank.compareTo(first.rank));

    entries.add(ExportEntry(
      entry,
      tags: [
        for (final entryTag in entryTags)
          if (tagById[entryTag.tagId] case final tag?)
            ExportEntryTag(
              name: tag.name,
              tagType: tag.tagType,
              categoryName: categoryNameById[tag.categoryId],
              value: _finiteNumber(entryTag.value),
            )
      ],
      attachments: [
        for (final attachment in attachments)
          if (await AttachmentStorage.instance
                  .getLocalPath(attachment.filePath, attachment.type)
              case final sourcePath?)
            ExportAttachment(
              type: attachment.type,
              rank: attachment.rank,
              timeCreate: attachment.timeCreate,
              sourcePath: sourcePath,
            )
      ],
    ));
    onProgress?.call(entries.length / sortedEntries.length);
  }

  return ExportSnapshot(
    locale: locale,
    exportedAt: DateTime.now(),
    moodLabelOf: (mood) =>
        moodScaleProvider.levelOf(mood)?.displayLabel(localizations) ??
        Mood.defaultLabel(Mood.position(mood), localizations),
    moodScale: moodScaleProvider.levels,
    categories: [
      for (final category in tagsProvider.categories)
        ExportCategory(
          name: category.name,
          icon: category.icon,
          iconType: category.iconType,
          color: category.color,
          sortOrder: category.sortOrder,
        )
    ],
    tagDefinitions: [
      for (final tag in tagsProvider.tags)
        ExportTagDefinition(
          name: tag.name,
          tagType: tag.tagType,
          categoryName: categoryNameById[tag.categoryId],
          icon: tag.icon,
          iconType: tag.iconType,
          color: tag.color,
          sortOrder: tag.sortOrder,
        )
    ],
    entries: entries,
  );
}

int _byTimeThenId(Entry first, Entry second) {
  final byTime = first.timeCreate.compareTo(second.timeCreate);
  return byTime != 0 ? byTime : first.id!.compareTo(second.id!);
}

num? _finiteNumber(String? text) {
  final number = num.tryParse(text ?? '');
  return number != null && number.isFinite ? number : null;
}
