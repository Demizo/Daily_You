import 'dart:async';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/entry_dao.dart';
import 'package:daily_you/database/entry_image_dao.dart';
import 'package:daily_you/database/entry_tag_dao.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/time_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class EntryDraft {
  final Entry entry;
  final List<EntryTag> tags;
  final List<EntryImage> images;

  const EntryDraft({
    required this.entry,
    this.tags = const [],
    this.images = const [],
  });
}

/// [saved] is this builder's own previous result, so a caller editing a brand
/// new entry picks up the id it was just given.
typedef EntryDraftBuilder = EntryDraft Function(Entry? saved);

class EntryDraftSession {
  EntryDraftSession._(this._store);

  final EntryStore _store;
  Entry? _lastSaved;
  EntryDraftBuilder? _pendingBuild;
  Completer<Entry>? _pendingCompleter;
  bool _writing = false;

  Future<Entry> save(EntryDraftBuilder buildDraft) {
    _pendingBuild = buildDraft;
    _pendingCompleter ??= Completer<Entry>();
    final future = _pendingCompleter!.future;
    if (!_writing) {
      _writing = true;
      unawaited(_runPending());
    }
    return future;
  }

  Future<void> _runPending() async {
    while (_pendingBuild != null) {
      final buildDraft = _pendingBuild!;
      final completer = _pendingCompleter!;
      _pendingBuild = null;
      _pendingCompleter = null;
      try {
        final saved = await _store._writeDraft(buildDraft(_lastSaved));
        _lastSaved = saved;
        completer.complete(saved);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }
    _writing = false;
  }
}

typedef _TagWrite = ({List<EntryTag> tags, bool changed});

typedef _ImageWrite = ({
  List<EntryImage> images,
  List<String> removedFiles,
  bool changed
});

class EntryStore with ChangeNotifier {
  static final EntryStore instance = EntryStore._init();

  EntryStore._init();

  List<Entry> _entries = List.empty(growable: true);

  List<Entry> get entries => _entries;

  @visibleForTesting
  set entries(List<Entry> entries) {
    _entries = entries;
    _indexEntriesByDay();
  }

  Map<DateTime, List<Entry>> _entriesByDay = {};

  EntryDraftSession beginDraft() => EntryDraftSession._(this);

  Future<void> load() async {
    _entries = await EntryDao.getAll();
    _indexEntriesByDay();
    notifyListeners();
  }

  Future<void> delete(Entry entry) async {
    final images = EntryImagesProvider.instance.getForEntry(entry);

    await AppDatabase.instance.database!.transaction((transaction) async {
      for (final image in images) {
        await EntryImageDao.remove(image, executor: transaction);
      }
      await EntryTagDao.removeAllForEntry(entry.id!, executor: transaction);
      await EntryDao.remove(entry.id!, executor: transaction);
    });

    await _deleteImageFiles(images.map((image) => image.imgPath));

    _entries = _entries.where((existing) => existing.id != entry.id).toList();
    _indexEntriesByDay();
    TagsProvider.instance.applyEntryTags(entry.id!, const []);
    EntryImagesProvider.instance.applyForEntry(entry.id!, const []);
    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
  }

  Future<Entry> add(Entry entry, {bool skipUpdate = false}) async {
    final entryWithId = await EntryDao.add(entry);
    _entries = [..._entries, entryWithId];
    await AppDatabase.instance.updateExternalDatabase();

    if (!skipUpdate) {
      _sortEntries();
      _indexEntriesByDay();
      notifyListeners();
    }
    return entryWithId;
  }

  Future<void> deleteAll(Function(String) updateStatus) async {
    updateStatus("0%");
    final allEntries = entries.toList();
    var processedEntries = 0;
    for (final entry in allEntries) {
      await delete(entry);
      processedEntries += 1;
      updateStatus(
          "${((processedEntries / allEntries.length) * 100).round()}%");
    }

    await load();
    await AppDatabase.instance.updateExternalDatabase();
  }

  int getIndexOfEntry(int entryId) {
    return entries.indexWhere((entry) => entry.id == entryId);
  }

  Entry? getEntryForToday() {
    if (entries.isNotEmpty && TimeManager.isToday(entries.first.timeCreate)) {
      return entries.first;
    }
    return null;
  }

  Entry? getEntryForDate(DateTime date) {
    return getEntriesForDate(date).firstOrNull;
  }

  List<Entry> getEntriesForDate(DateTime date) {
    return _entriesByDay[DateTime(date.year, date.month, date.day)] ?? const [];
  }

  int getEntryDayCount() => _entriesByDay.length;

  bool hasEntryAtTimestamp(DateTime timestamp) {
    return entries.any((entry) => entry.timeCreate == timestamp);
  }

  Future<Entry> _writeDraft(EntryDraft draft) async {
    late Entry saved;
    late _TagWrite tagWrite;
    late _ImageWrite imageWrite;
    final entryChanged = _entryNeedsWrite(draft.entry);

    await AppDatabase.instance.database!.transaction((transaction) async {
      if (draft.entry.id == null) {
        saved = await EntryDao.add(draft.entry, executor: transaction);
      } else {
        if (entryChanged) {
          await EntryDao.update(draft.entry, executor: transaction);
        }
        saved = draft.entry;
      }
      tagWrite = await _writeEntryTags(transaction, saved.id!, draft.tags);
      imageWrite = await _writeEntryImages(transaction, saved, draft.images);
    });

    if (!entryChanged && !tagWrite.changed && !imageWrite.changed) return saved;

    await _deleteImageFiles(imageWrite.removedFiles);

    final index = getIndexOfEntry(saved.id!);
    if (index == -1) {
      _entries = [..._entries, saved];
    } else {
      _entries = [..._entries]..[index] = saved;
    }
    _sortEntries();
    _indexEntriesByDay();

    TagsProvider.instance.applyEntryTags(saved.id!, tagWrite.tags);
    EntryImagesProvider.instance.applyForEntry(saved.id!, imageWrite.images);

    await AppDatabase.instance.updateExternalDatabase();
    notifyListeners();
    return saved;
  }

  bool _entryNeedsWrite(Entry entry) {
    if (entry.id == null) return true;
    final index = getIndexOfEntry(entry.id!);
    if (index == -1) return true;
    final stored = entries[index];
    return stored.text != entry.text ||
        stored.mood != entry.mood ||
        stored.timeCreate != entry.timeCreate ||
        stored.timeModified != entry.timeModified;
  }

  Future<_TagWrite> _writeEntryTags(
      DatabaseExecutor executor, int entryId, List<EntryTag> desired) async {
    // Tags can be deleted while editing entries, drop dead tags
    final liveTagIds = TagsProvider.instance.tags.map((tag) => tag.id).toSet();
    final current = TagsProvider.instance.getEntryTagsForEntry(entryId);
    final currentByTag = {
      for (final entryTag in current) entryTag.tagId: entryTag
    };
    final desiredTagIds = desired
        .map((entryTag) => entryTag.tagId)
        .where(liveTagIds.contains)
        .toSet();
    var changed = false;

    for (final entryTag in current) {
      if (desiredTagIds.contains(entryTag.tagId)) continue;
      await EntryTagDao.remove(entryTag.id!, executor: executor);
      changed = true;
    }

    final written = <EntryTag>[];
    for (final wanted in desired) {
      if (!liveTagIds.contains(wanted.tagId)) continue;
      final existing = currentByTag[wanted.tagId];
      if (existing == null) {
        written.add(await EntryTagDao.add(
          EntryTag(
            entryId: entryId,
            tagId: wanted.tagId,
            value: wanted.value,
            timeCreate: wanted.timeCreate,
          ),
          executor: executor,
        ));
        changed = true;
      } else if (existing.value != wanted.value) {
        final updated = EntryTag(
          id: existing.id,
          entryId: entryId,
          tagId: wanted.tagId,
          value: wanted.value,
          timeCreate: existing.timeCreate,
        );
        await EntryTagDao.update(updated, executor: executor);
        written.add(updated);
        changed = true;
      } else {
        written.add(existing);
      }
    }
    return (tags: written, changed: changed);
  }

  Future<_ImageWrite> _writeEntryImages(
      DatabaseExecutor executor, Entry entry, List<EntryImage> desired) async {
    final current = EntryImagesProvider.instance.getForEntry(entry);
    final written = <EntryImage>[];
    var changed = false;

    for (final image in desired) {
      final wanted = image.copy(entryId: entry.id);
      final existing =
          current.where((saved) => saved.id == wanted.id).firstOrNull;
      if (existing == null) {
        written.add(await EntryImageDao.add(wanted, executor: executor));
        changed = true;
      } else if (existing.imgRank != wanted.imgRank) {
        await EntryImageDao.update(wanted, executor: executor);
        written.add(wanted);
        changed = true;
      } else {
        written.add(existing);
      }
    }

    final desiredIds = desired.map((image) => image.id).nonNulls.toSet();
    final removedFiles = <String>[];
    for (final existing in current) {
      if (desiredIds.contains(existing.id)) continue;
      await EntryImageDao.remove(existing, executor: executor);
      removedFiles.add(existing.imgPath);
      changed = true;
    }

    return (images: written, removedFiles: removedFiles, changed: changed);
  }

  Future<void> _deleteImageFiles(Iterable<String> names) async {
    for (final name in names) {
      await ImageStorage.instance.delete(name);
    }
  }

  void _sortEntries() {
    _entries.sort((a, b) => _compareDateOnly(b.timeCreate, a.timeCreate));
  }

  void _indexEntriesByDay() {
    final index = <DateTime, List<Entry>>{};
    for (final entry in _entries) {
      final key = DateTime(
          entry.timeCreate.year, entry.timeCreate.month, entry.timeCreate.day);
      index.putIfAbsent(key, () => []).add(entry);
    }
    _entriesByDay = index;
  }
}

int _compareDateOnly(DateTime a, DateTime b) {
  if (a.year != b.year) return a.year.compareTo(b.year);
  if (a.month != b.month) return a.month.compareTo(b.month);
  if (a.day != b.day) return a.day.compareTo(b.day);
  if (a.hour != b.hour) return a.hour.compareTo(b.hour);
  return a.minute.compareTo(b.minute);
}
