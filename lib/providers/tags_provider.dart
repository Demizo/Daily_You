import 'dart:math';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/tag_category_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/database/template_tag_dao.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:flutter/material.dart';

class TagSection {
  final TagCategory? category;
  final List<Tag> tags;

  const TagSection({this.category, required this.tags});
}

class TagsProvider with ChangeNotifier {
  static final TagsProvider instance = TagsProvider._init();

  TagsProvider._init();

  List<TagCategory> categories = List.empty();
  List<Tag> tags = List.empty();

  List<EntryTag> _entryTags = List.empty();
  List<EntryTag> get entryTags => _entryTags;

  Map<int, List<EntryTag>> _entryTagsByEntry = const {};

  List<TemplateTag> _templateTags = List.empty();
  List<TemplateTag> get templateTags => _templateTags;

  Map<int, List<TemplateTag>> _templateTagsByTemplate = const {};

  void _setEntryTags(List<EntryTag> updated) {
    _entryTags = updated;
    final grouped = <int, List<EntryTag>>{};
    for (final entryTag in updated) {
      (grouped[entryTag.entryId] ??= []).add(entryTag);
    }
    _entryTagsByEntry = grouped;
  }

  void _setTemplateTags(List<TemplateTag> updated) {
    _templateTags = updated;
    final grouped = <int, List<TemplateTag>>{};
    for (final templateTag in updated) {
      (grouped[templateTag.templateId] ??= []).add(templateTag);
    }
    _templateTagsByTemplate = grouped;
  }

  Future<void> load() async {
    categories = await TagCategoryDao.getAll();
    tags = await TagDao.getAll();
    _setEntryTags(await EntryTagDao.getAll());
    _setTemplateTags(await TemplateTagDao.getAll());
    notifyListeners();
  }

  Future<TagCategory> addCategory(TagCategory category) async {
    final nextOrder = categories.isEmpty
        ? 0
        : categories.map((existing) => existing.sortOrder).reduce(max) + 1;
    final withOrder = category.copy(sortOrder: nextOrder);
    final withId = await TagCategoryDao.add(withOrder);
    categories = [...categories, withId];
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
    return withId;
  }

  Future<void> updateCategory(TagCategory category) async {
    await TagCategoryDao.update(category);
    categories = [
      for (final existing in categories)
        existing.id == category.id ? category : existing
    ];
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> updateCategorySortOrders(
      List<TagCategory> orderedCategories) async {
    final updated = <TagCategory>[];
    for (int index = 0; index < orderedCategories.length; index++) {
      final category = orderedCategories[index].copy(sortOrder: index);
      await TagCategoryDao.update(category);
      updated.add(category);
    }
    final updatedMap = {for (final category in updated) category.id: category};
    categories = [
      for (final category in categories) updatedMap[category.id] ?? category
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> add(Tag tag) async {
    final nextOrder = tags.isEmpty
        ? 0
        : tags.map((existing) => existing.sortOrder).reduce(max) + 1;
    final tagWithOrder = tag.copy(sortOrder: nextOrder);
    final tagWithId = await TagDao.add(tagWithOrder);
    tags = [...tags, tagWithId];
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> remove(Tag tag) async {
    await EntryTagDao.removeAllForTag(tag.id!);
    _setEntryTags(
        entryTags.where((entryTag) => entryTag.tagId != tag.id).toList());
    await TemplateTagDao.removeAllForTag(tag.id!);
    _setTemplateTags(templateTags
        .where((templateTag) => templateTag.tagId != tag.id)
        .toList());
    await TagDao.remove(tag.id!);
    tags = tags.where((existing) => existing.id != tag.id).toList();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> update(Tag tag) async {
    await TagDao.update(tag);
    tags = [
      for (final existing in tags) existing.id == tag.id ? tag : existing
    ];
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> batchUpdateTags(List<Tag> updatedTags) async {
    // Apply in-memory immediately so the reorderable list doesn't snap back
    // while the DB writes below are still in flight.
    final updatedMap = {for (final tag in updatedTags) tag.id: tag};
    tags = [for (final existing in tags) updatedMap[existing.id] ?? existing]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
    for (final tag in updatedTags) {
      await TagDao.update(tag);
    }
    await AppDatabase.instance.updateExternalDatabase();
  }

  Future<void> addEntryTag(EntryTag entryTag) async {
    final entryTagWithId = await EntryTagDao.add(entryTag);
    _setEntryTags([...entryTags, entryTagWithId]);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> updateEntryTag(EntryTag entryTag) async {
    await EntryTagDao.update(entryTag);
    _setEntryTags([
      for (final existing in entryTags)
        existing.id == entryTag.id ? entryTag : existing
    ]);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removeEntryTag(EntryTag entryTag) async {
    await EntryTagDao.remove(entryTag.id!);
    _setEntryTags(
        entryTags.where((existing) => existing.id != entryTag.id).toList());
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removeAllEntryTagsForEntry(int entryId) async {
    await EntryTagDao.removeAllForEntry(entryId);
    _setEntryTags(
        entryTags.where((entryTag) => entryTag.entryId != entryId).toList());
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  List<EntryTag> getEntryTagsForEntry(int entryId) {
    return _entryTagsByEntry[entryId] ?? const [];
  }

  /// Reconciles the tags stored for [entryId] with [desired], adding, removing,
  /// and updating rows so the database matches.
  Future<void> setEntryTags(int entryId, List<EntryTag> desired) async {
    final current = getEntryTagsForEntry(entryId);
    final currentByTag = {
      for (final entryTag in current) entryTag.tagId: entryTag
    };
    final desiredByTag = {
      for (final entryTag in desired) entryTag.tagId: entryTag
    };
    var changed = false;

    for (final entryTag in current) {
      if (!desiredByTag.containsKey(entryTag.tagId)) {
        await EntryTagDao.remove(entryTag.id!);
        changed = true;
      }
    }

    final result = <EntryTag>[];
    for (final wanted in desired) {
      final existing = currentByTag[wanted.tagId];
      if (existing == null) {
        result.add(await EntryTagDao.add(EntryTag(
          entryId: entryId,
          tagId: wanted.tagId,
          value: wanted.value,
          timeCreate: wanted.timeCreate,
        )));
        changed = true;
      } else if (existing.value != wanted.value) {
        final updated = EntryTag(
          id: existing.id,
          entryId: entryId,
          tagId: wanted.tagId,
          value: wanted.value,
          timeCreate: existing.timeCreate,
        );
        await EntryTagDao.update(updated);
        result.add(updated);
        changed = true;
      } else {
        result.add(existing);
      }
    }

    if (!changed) return;

    final retained =
        entryTags.where((entryTag) => entryTag.entryId != entryId).toList();
    _setEntryTags([...retained, ...result]);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  /// Reconciles the tags stored for [templateId] with [tagIds], adding and
  /// removing rows so the database matches.
  Future<void> setTemplateTags(int templateId, List<int> tagIds) async {
    final current = getTemplateTagsForTemplate(templateId);
    final currentIds = current.map((templateTag) => templateTag.tagId).toSet();
    final desiredIds = tagIds.toSet();

    for (final templateTag in current) {
      if (!desiredIds.contains(templateTag.tagId)) {
        await TemplateTagDao.remove(templateTag.id!);
      }
    }

    final added = <TemplateTag>[];
    for (final tagId in tagIds) {
      if (currentIds.contains(tagId)) continue;
      added.add(await TemplateTagDao.add(TemplateTag(
        templateId: templateId,
        tagId: tagId,
        timeCreate: DateTime.now(),
      )));
    }

    final retained = templateTags
        .where((templateTag) =>
            templateTag.templateId != templateId ||
            desiredIds.contains(templateTag.tagId))
        .toList();
    _setTemplateTags([...retained, ...added]);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> removeAllTemplateTagsForTemplate(int templateId) async {
    await TemplateTagDao.removeAllForTemplate(templateId);
    _setTemplateTags(templateTags
        .where((templateTag) => templateTag.templateId != templateId)
        .toList());
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  List<TemplateTag> getTemplateTagsForTemplate(int templateId) {
    return _templateTagsByTemplate[templateId] ?? const [];
  }

  int entryCountForTag(int tagId) {
    return entryTags
        .where((entryTag) => entryTag.tagId == tagId)
        .map((entryTag) => entryTag.entryId)
        .toSet()
        .length;
  }

  /// Returns tags grouped into sections filtered by [searchText].
  /// A tag matches if its name or its category name contains [searchText].
  /// Uncategorized tags come first (no header), named categories follow in
  /// sort order. Sections with no matching tags are omitted.
  /// [tagPool] defaults to [tags] when null.
  List<TagSection> buildSections(String searchText, {List<Tag>? tagPool}) {
    final pool = tagPool ?? tags;
    final query = searchText.toLowerCase();

    bool tagMatches(Tag tag) {
      if (query.isEmpty) return true;
      if (tag.name.toLowerCase().contains(query)) return true;
      final category =
          categories.where((c) => c.id == tag.categoryId).firstOrNull;
      return category != null && category.name.toLowerCase().contains(query);
    }

    final sections = <TagSection>[];

    final uncategorized =
        pool.where((tag) => tag.categoryId == null && tagMatches(tag)).toList();
    if (uncategorized.isNotEmpty) {
      sections.add(TagSection(category: null, tags: uncategorized));
    }

    for (final category in categories) {
      final matched = pool
          .where((tag) => tag.categoryId == category.id && tagMatches(tag))
          .toList();
      if (matched.isNotEmpty) {
        sections.add(TagSection(category: category, tags: matched));
      }
    }

    return sections;
  }

  /// Deletes [category] and removes all tags belonging to it.
  Future<void> removeCategoryAndTags(TagCategory category) async {
    final affected =
        tags.where((tag) => tag.categoryId == category.id).toList();
    for (final tag in affected) {
      await EntryTagDao.removeAllForTag(tag.id!);
      await TemplateTagDao.removeAllForTag(tag.id!);
    }
    _setEntryTags(entryTags
        .where((entryTag) => !affected.any((tag) => tag.id == entryTag.tagId))
        .toList());
    _setTemplateTags(templateTags
        .where((templateTag) =>
            !affected.any((tag) => tag.id == templateTag.tagId))
        .toList());
    for (final tag in affected) {
      await TagDao.remove(tag.id!);
    }
    tags = tags.where((tag) => tag.categoryId != category.id).toList();

    await TagCategoryDao.remove(category.id!);
    categories =
        categories.where((existing) => existing.id != category.id).toList();
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<void> createDefaultTags() async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    Locale locale;
    if (AppLocalizations.delegate.isSupported(deviceLocale)) {
      locale = deviceLocale;
    } else {
      final langOnly = Locale(deviceLocale.languageCode);
      locale = AppLocalizations.delegate.isSupported(langOnly)
          ? langOnly
          : const Locale('en');
    }
    final l10n = await AppLocalizations.delegate.load(locale);
    final now = DateTime.now();

    final defaultTags = [
      Tag(
        name: l10n.tagFavoriteName,
        tagType: TagType.label,
        icon: TagIconKey.favorite,
        iconType: TagIconType.materialIcon,
        color: Colors.pink.shade500.toARGB32(),
        timeCreate: now,
        timeModified: now,
      ),
      Tag(
        name: l10n.tagEnergyName,
        tagType: TagType.tracker,
        icon: TagIconKey.batteryChargingFull,
        iconType: TagIconType.materialIcon,
        color: Colors.green.shade600.toARGB32(),
        timeCreate: now,
        timeModified: now,
      ),
    ];
    for (final tag in defaultTags) {
      await add(tag);
    }

    final emotionsCategory = await addCategory(TagCategory(
      name: l10n.tagCategoryEmotionsName,
      icon: TagIconKey.sentimentVerySatisfied,
      iconType: TagIconType.materialIcon,
      timeCreate: now,
      timeModified: now,
    ));

    final defaultEmotionTags = [
      (l10n.tagExcitedName, TagIconKey.celebration),
      (l10n.tagGratefulName, TagIconKey.volunteerActivism),
      (l10n.tagCalmName, TagIconKey.spa),
      (l10n.tagTiredName, TagIconKey.nightlight),
      (l10n.tagAnxiousName, TagIconKey.psychology),
      (l10n.tagAnnoyedName, TagIconKey.thunderstorm),
    ];
    for (final (name, icon) in defaultEmotionTags) {
      await add(Tag(
        categoryId: emotionsCategory.id,
        name: name,
        tagType: TagType.label,
        icon: icon,
        iconType: TagIconType.materialIcon,
        timeCreate: now,
        timeModified: now,
      ));
    }

    final activitiesCategory = await addCategory(TagCategory(
      name: l10n.tagCategoryActivitiesName,
      icon: TagIconKey.directionsRun,
      iconType: TagIconType.materialIcon,
      timeCreate: now,
      timeModified: now,
    ));

    final defaultActivityTags = [
      (l10n.tagExerciseName, TagIconKey.fitnessCenter),
      (l10n.tagSocializingName, TagIconKey.groups),
      (l10n.tagHobbyName, TagIconKey.palette),
      (l10n.tagEntertainmentName, TagIconKey.theaterComedy),
      (l10n.tagDiningName, TagIconKey.localDining),
      (l10n.tagChoresName, TagIconKey.cleaningServices),
    ];
    for (final (name, icon) in defaultActivityTags) {
      await add(Tag(
        categoryId: activitiesCategory.id,
        name: name,
        tagType: TagType.label,
        icon: icon,
        iconType: TagIconType.materialIcon,
        timeCreate: now,
        timeModified: now,
      ));
    }
  }
}
