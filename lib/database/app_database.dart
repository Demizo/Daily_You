// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/mood_scale_dao.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/external_sync_health.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseNewerThanAppException implements Exception {
  final int databaseVersion;

  const DatabaseNewerThanAppException(this.databaseVersion);

  @override
  String toString() =>
      'Database schema version $databaseVersion is newer than the supported '
      'version ${AppDatabase.schemaVersion}';
}

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  AppDatabase._init();

  static DatabaseExecutor executorOr(DatabaseExecutor? executor) =>
      executor ?? instance.database!;

  static const String databaseFileName = 'daily_you.db';

  final Logger _logger = Logger('AppDatabase');

  final ExternalSyncHealth externalSyncHealth =
      ExternalSyncHealth('AppDatabase');

  /// True when a migration from external storage was attempted on the last
  /// [init] but failed.
  bool migrationFailed = false;

  bool databaseReplacedThisSession = false;

  static Database? _database;
  Database? get database => _database;

  @visibleForTesting
  set database(Database? database) => _database = database;

  String? _internalPath;

  FileStore get internalStore => LocalFileStore(dirname(_internalPath!));

  FileStore? get externalStore {
    final location = ExternalSyncSettings.load().location(SyncItem.logs);
    return location == null ? null : FileStore.external(location.uri);
  }

  Future<bool> init(
      {bool forceWithoutSync = false, bool allowMigration = true}) async {
    _internalPath = await getInternalPath();
    migrationFailed = false;
    databaseReplacedThisSession = false;
    bool success = true;

    if (Platform.isAndroid && allowMigration) {
      final migrated = await _migrateDbFromExternalStorage();
      if (!migrated && !forceWithoutSync) {
        // Migration was attempted but failed
        migrationFailed = true;
        return false;
      }
    }

    // Migration is foreground-only. A background task (allowMigration: false)
    // must never create a fresh database before the user has migrated their
    // data, so bail if there is nothing to open yet.
    if (!allowMigration && !await File(_internalPath!).exists()) {
      return false;
    }

    if (usingExternalLocation() && !forceWithoutSync) {
      if (await hasExternalLocationPermission()) {
        await _syncWithExternalDatabase();
      } else {
        success = false;
      }
    }

    await AppDatabase.instance.open();
    return success;
  }

  /// Returns whether it is safe to open the internal database. False means a
  /// migration was needed but failed, so the caller must not create a fresh
  /// database over the still-intact external copy.
  Future<bool> _migrateDbFromExternalStorage() async {
    if (await File(_internalPath!).exists()) return true;

    final oldDir = await getExternalStorageDirectory();
    if (oldDir == null) return true;
    final oldPath = join(oldDir.path, databaseFileName);
    if (!await File(oldPath).exists()) return true;

    _logger.info('Database migration started: $oldPath -> $_internalPath');
    try {
      await File(oldPath).copy(_internalPath!);
      if (await _validateSqliteDatabase(_internalPath!)) {
        await File(oldPath).delete();
        _logger.info('Database migration finished successfully');
        return true;
      }
      // Integrity check failed: discard the bad copy and keep the external
      // original so the migration can be retried instead of proceeding.
      await File(_internalPath!).delete();
      _logger.severe(
          'Database migration failed: integrity check failed, kept original external database');
      return false;
    } catch (error, stackTrace) {
      // Remove any partial copy so the migration is retried on relaunch.
      if (await File(_internalPath!).exists()) {
        await File(_internalPath!).delete();
      }
      _logger.severe('Database migration failed', error, stackTrace);
      return false;
    }
  }

  static const schemaVersion = 7;

  Future<void> open() async {
    _database = await openDatabase(_internalPath!,
        version: schemaVersion,
        onCreate: _createDatabase,
        onUpgrade: onUpgrade,
        onDowngrade: (db, oldVersion, newVersion) =>
            throw DatabaseNewerThanAppException(oldVersion));

    await EntriesProvider.instance.load();
    await EntryAttachmentsProvider.instance.load();
    await TemplatesProvider.instance.load();
    await TagsProvider.instance.load();
    await MoodScaleProvider.instance.load();
  }

  Future<void> close() async {
    final db = _database!;
    _database = null;
    await db.close();
  }

  Future<void> replaceDatabase(File replacement) async {
    const previousName = '$databaseFileName.previous';
    final store = LocalFileStore(dirname(_internalPath!));
    await close();
    var movedAside = false;
    try {
      await store.delete(previousName);
      movedAside = await store.rename(databaseFileName, previousName);
      await store.writeAtomically(databaseFileName, (temporary) async {
        await replacement.copy(temporary.path);
        return true;
      });
      await open();
    } catch (_) {
      if (_database != null) await close();
      if (movedAside) await store.rename(previousName, databaseFileName);
      await open();
      rethrow;
    }
    await store.delete(previousName);
  }

  Future<bool> _validateSqliteDatabase(String path) async {
    try {
      final db = await openDatabase(path, readOnly: true);
      final result = await db.rawQuery("PRAGMA integrity_check;");
      await db.close();

      return result.first.values.first == "ok";
    } catch (error, stackTrace) {
      _logger.warning(
          'Database integrity check failed for $path', error, stackTrace);
      return false;
    }
  }

  Future<bool> canOpen(String path) async {
    if (!await _validateSqliteDatabase(path)) return false;
    final db = await openDatabase(path, readOnly: true);
    try {
      final version = await db.getVersion();
      if (version > schemaVersion) throw DatabaseNewerThanAppException(version);
      return version > 0 && await _tableExists(db, entriesTable);
    } finally {
      await db.close();
    }
  }

  Future<bool> exportSnapshotTo(String path) async {
    final db = _database;
    if (db == null) return false;

    try {
      await db.execute("VACUUM INTO '$path'");
      if (await _validateSqliteDatabase(path)) return true;
    } catch (error, stackTrace) {
      _logger.severe('Database snapshot to $path failed', error, stackTrace);
    }

    if (await File(path).exists()) await File(path).delete();
    return false;
  }

  bool usingExternalLocation() =>
      ExternalSyncSettings.load().location(SyncItem.logs) != null;

  Future<String> getInternalPath() async {
    final basePath = await getApplicationSupportDirectory();
    if (!basePath.existsSync()) basePath.createSync(recursive: true);
    return join(basePath.path, databaseFileName);
  }

  /// Return whether the app has permission to access the external location
  Future<bool> hasExternalLocationPermission() async {
    return await externalStore?.isAvailable() ?? false;
  }

  Future<OperationOutcome> syncFromExternalLocation() async {
    var outcome = const OperationOutcome.succeeded();
    await close();

    try {
      if (!await _syncWithExternalDatabase(forceOverwrite: true)) {
        outcome = const OperationOutcome.failed();
      }
    } catch (error, stackTrace) {
      _logger.severe(
          'Syncing with the external database failed', error, stackTrace);
      outcome = OperationOutcome.failed(error);
    }

    await open();
    return outcome;
  }

  Future<bool> hasExternalDatabase(String uri) async {
    try {
      return await FileStore.external(uri).exists(databaseFileName);
    } catch (error, stackTrace) {
      _logger.warning(
          'Could not look for a database in $uri', error, stackTrace);
      return true;
    }
  }

  /// Overwrite the external database with local changes
  /// If an external database is not in use, no action is taken
  Future<void> updateExternalDatabase() async {
    if (!usingExternalLocation()) return;

    EasyDebounce.debounce("update-remote-database", Duration(seconds: 1),
        () async {
      final externalLocation = externalStore;
      if (externalLocation == null) return;

      final exportName =
          "$databaseFileName.export_${DateTime.now().millisecondsSinceEpoch}";
      final exportPath = join(dirname(_internalPath!), exportName);

      await externalSyncHealth.record("external database write", () async {
        try {
          if (!await exportSnapshotTo(exportPath)) return false;

          final bytes = await internalStore.read(exportName);
          if (bytes == null) return false;

          return await externalLocation.write(databaseFileName, bytes);
        } finally {
          await internalStore.delete(exportName);
        }
      });
    });
  }

  /// Pull in remote changes if the external database is newer or if forceOverwrite is set
  Future<bool> _syncWithExternalDatabase({bool forceOverwrite = false}) async {
    final externalLocation = externalStore;
    if (externalLocation == null) return false;

    if (!await externalLocation.exists(databaseFileName)) {
      final bytes = await internalStore.read(databaseFileName);
      if (bytes == null) return false;

      return externalSyncHealth.record("external database write",
          () => externalLocation.write(databaseFileName, bytes));
    }

    if (forceOverwrite || await _isExternalDatabaseNewer(externalLocation)) {
      // Overwrite internal DB
      final externalBytes = await externalLocation.read(databaseFileName);
      if (externalBytes == null) return false;

      final temporaryName =
          "$databaseFileName.${DateTime.now().millisecondsSinceEpoch}.tmp";
      await internalStore.write(temporaryName, externalBytes);

      final temporaryPath = join(dirname(_internalPath!), temporaryName);
      var accepted = false;
      try {
        accepted = await canOpen(temporaryPath);
        if (accepted) {
          final replaced =
              await internalStore.rename(temporaryName, databaseFileName);
          if (replaced) databaseReplacedThisSession = true;
          return replaced;
        }
        return false;
      } finally {
        if (!accepted) await internalStore.delete(temporaryName);
      }
    }
    return true;
  }

  /// Return whether the external database is newer
  Future<bool> _isExternalDatabaseNewer(FileStore externalLocation) async {
    final internalModifiedTime =
        await internalStore.modifiedTime(databaseFileName) ?? DateTime.now();

    final externalModifiedTime =
        await externalLocation.modifiedTime(databaseFileName) ??
            internalModifiedTime;

    return externalModifiedTime.isAfter(internalModifiedTime);
  }

  // SQLite Database Actions

  Future _createDatabase(Database db, int version) async {
    databaseReplacedThisSession = true;
    _database = db;
    await createSchema(db);
    await TemplatesProvider.instance.createDefaultTemplates();
    await TagsProvider.instance.createDefaultTags();
    await MoodScaleDao.save(MoodScalePreset.emoji.levels, executor: db);
    await createWelcomeEntry();
  }

  Future<void> createSchema(Database db) async {
    await db.execute('''
CREATE TABLE $entriesTable (
  ${EntryFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${EntryFields.text} TEXT NOT NULL,
  ${EntryFields.mood} INTEGER,
  ${EntryFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${EntryFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
)
''');
    await db.execute('''
CREATE TABLE $templatesTable (
  ${TemplatesFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${TemplatesFields.name} TEXT NOT NULL,
  ${TemplatesFields.text} TEXT,
  ${TemplatesFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${TemplatesFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
)
''');
    await db.execute('''
CREATE TABLE $attachmentsTable (
    ${EntryAttachmentFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntryAttachmentFields.entryId} INTEGER NOT NULL,
    ${EntryAttachmentFields.type} TEXT NOT NULL,
    ${EntryAttachmentFields.filePath} TEXT NOT NULL,
    ${EntryAttachmentFields.rank} INTEGER NOT NULL,
    ${EntryAttachmentFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntryAttachmentFields.entryId}) REFERENCES $entriesTable (id)
)
''');

    await _createTagTables(db);
    await _createMoodScaleLevelsTable(db);
    await _createTemplateTagTable(db);
  }

  @visibleForTesting
  Future<void> createWelcomeEntry() async {
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

    final welcomeEntry = await EntriesProvider.instance.add(
      Entry(
        text: l10n.welcomeLogBodyText,
        mood: Mood.pleasant,
        timeCreate: now,
        timeModified: now,
      ),
      skipUpdate: true,
    );

    final imageBytes =
        await rootBundle.load('assets/daily_you_First_Steps.webp');
    final imageName = await AttachmentStorage.instance.create(
      'daily_you_First_Steps.webp',
      imageBytes.buffer.asUint8List(),
      AttachmentType.image,
      currTime: now,
    );
    if (imageName != null) {
      await EntryAttachmentsProvider.instance.add(
        EntryAttachment(
          entryId: welcomeEntry.id,
          type: AttachmentType.image,
          filePath: imageName,
          rank: 0,
          timeCreate: now,
        ),
        skipUpdate: true,
      );
    }

    final favoriteTag = TagsProvider.instance.tags
        .where((tag) => tag.icon == TagIconKey.favorite)
        .firstOrNull;
    if (favoriteTag != null) {
      await TagsProvider.instance.addEntryTag(EntryTag(
        entryId: welcomeEntry.id!,
        tagId: favoriteTag.id!,
        timeCreate: now,
      ));
    }

    final energyTag = TagsProvider.instance.tags
        .where((tag) => tag.icon == TagIconKey.batteryChargingFull)
        .firstOrNull;
    if (energyTag != null) {
      await TagsProvider.instance.addEntryTag(EntryTag(
        entryId: welcomeEntry.id!,
        tagId: energyTag.id!,
        value: '10',
        timeCreate: now,
      ));
    }
  }

  Future<void> _createTagTables(Database db) async {
    await db.execute('''
CREATE TABLE $tagCategoriesTable (
    ${TagCategoryFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${TagCategoryFields.icon} TEXT,
    ${TagCategoryFields.iconType} INTEGER NOT NULL DEFAULT 0,
    ${TagCategoryFields.name} TEXT NOT NULL,
    ${TagCategoryFields.color} INTEGER,
    ${TagCategoryFields.sortOrder} INTEGER NOT NULL DEFAULT 0,
    ${TagCategoryFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    ${TagCategoryFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
)
''');

    await db.execute('''
CREATE TABLE $tagsTable (
    ${TagFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${TagFields.categoryId} INTEGER,
    ${TagFields.icon} TEXT,
    ${TagFields.iconType} INTEGER NOT NULL DEFAULT 0,
    ${TagFields.name} TEXT NOT NULL,
    ${TagFields.tagType} INTEGER NOT NULL,
    ${TagFields.color} INTEGER,
    ${TagFields.sortOrder} INTEGER NOT NULL DEFAULT 0,
    ${TagFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    ${TagFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${TagFields.categoryId}) REFERENCES $tagCategoriesTable (id)
)
''');

    await db.execute('''
CREATE TABLE $entryTagsTable (
    ${EntryTagFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntryTagFields.entryId} INTEGER NOT NULL,
    ${EntryTagFields.tagId} INTEGER NOT NULL,
    ${EntryTagFields.value} TEXT,
    ${EntryTagFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntryTagFields.entryId}) REFERENCES $entriesTable (id),
    FOREIGN KEY (${EntryTagFields.tagId}) REFERENCES $tagsTable (id)
)
''');
  }

  Future<void> _createMoodScaleLevelsTable(Database db) async {
    await db.execute('''
CREATE TABLE $moodScaleTable (
  ${MoodScaleLevelFields.mood} INTEGER NOT NULL PRIMARY KEY,
  ${MoodScaleLevelFields.label} TEXT,
  ${MoodScaleLevelFields.icon} TEXT,
  ${MoodScaleLevelFields.iconType} INTEGER NOT NULL DEFAULT 0,
  ${MoodScaleLevelFields.color} INTEGER
)
''');
  }

  Future<void> _createTemplateTagTable(Database db) async {
    await db.execute('''
CREATE TABLE $templateTagsTable (
    ${TemplateTagFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${TemplateTagFields.templateId} INTEGER NOT NULL,
    ${TemplateTagFields.tagId} INTEGER NOT NULL,
    ${TemplateTagFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${TemplateTagFields.templateId}) REFERENCES $templatesTable (id),
    FOREIGN KEY (${TemplateTagFields.tagId}) REFERENCES $tagsTable (id)
)
''');
  }

  @visibleForTesting
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    _database = db;
    // In this case, oldVersion is 1, newVersion is 2
    if (oldVersion == 1) {
      await db.execute('''
CREATE TABLE $templatesTable (
  ${TemplatesFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${TemplatesFields.name} TEXT NOT NULL,
  ${TemplatesFields.text} TEXT,
  ${TemplatesFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${TemplatesFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
)
''');

      await TemplatesProvider.instance.createDefaultTemplates();
    }
    if (oldVersion <= 2) {
      await db.execute('''
CREATE TABLE entry_images (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL,
    img_path TEXT NOT NULL,
    img_rank INTEGER NOT NULL,
    time_create DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (entry_id) REFERENCES $entriesTable (id)
)
''');
      await db.transaction((txn) async {
        await txn.execute('''
-- Step 1: Insert the non-null imgPath entries into entry_images
INSERT INTO entry_images (entry_id, img_path, img_rank, time_create)
SELECT ${EntryFields.id}, $deprecatedImgPath, 0, ${EntryFields.timeCreate}
FROM $entriesTable
WHERE $deprecatedImgPath IS NOT NULL;
    ''');

        await txn.execute('''
-- Step 2: Rename the old entries table
ALTER TABLE $entriesTable RENAME TO old_entries;
    ''');

        await txn.execute('''
-- Step 3: Create a new entries table without the imgPath field
CREATE TABLE $entriesTable (
  ${EntryFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${EntryFields.text} TEXT NOT NULL,
  ${EntryFields.mood} INTEGER,
  ${EntryFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${EntryFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
);
    ''');

        await txn.execute('''
-- Step 4: Copy data from the old entries table to the new one
INSERT INTO $entriesTable (${EntryFields.id}, ${EntryFields.text}, ${EntryFields.mood}, ${EntryFields.timeCreate}, ${EntryFields.timeModified})
SELECT ${EntryFields.id}, ${EntryFields.text}, ${EntryFields.mood}, ${EntryFields.timeCreate}, ${EntryFields.timeModified}
FROM old_entries;
    ''');

        await txn.execute('''
-- Step 5: Drop the old entries table
DROP TABLE old_entries;
    ''');
      });
    }
    if (oldVersion <= 3) {
      await _createTagTables(db);
      await TagsProvider.instance.createDefaultTags();
    }
    if (oldVersion <= 4) {
      await _createTemplateTagTable(db);
    }
    // An older app that pulled a version 6 database relabels it as version 5
    if (oldVersion <= 5 && !await _tableExists(db, attachmentsTable)) {
      await db.execute('''
CREATE TABLE $attachmentsTable (
    ${EntryAttachmentFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntryAttachmentFields.entryId} INTEGER NOT NULL,
    ${EntryAttachmentFields.type} TEXT NOT NULL,
    ${EntryAttachmentFields.filePath} TEXT NOT NULL,
    ${EntryAttachmentFields.rank} INTEGER NOT NULL,
    ${EntryAttachmentFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntryAttachmentFields.entryId}) REFERENCES $entriesTable (id)
)
''');
      await db.transaction((txn) async {
        await txn.execute('''
INSERT INTO $attachmentsTable (${EntryAttachmentFields.id}, ${EntryAttachmentFields.entryId}, ${EntryAttachmentFields.type}, ${EntryAttachmentFields.filePath}, ${EntryAttachmentFields.rank}, ${EntryAttachmentFields.timeCreate})
SELECT id, entry_id, 'image', img_path, img_rank, time_create
FROM entry_images
WHERE img_path IS NOT NULL AND img_path != ''
ORDER BY id;
    ''');
        await txn.execute(
            "DELETE FROM sqlite_sequence WHERE name = '$attachmentsTable';");
        await txn.execute('''
INSERT INTO sqlite_sequence (name, seq)
SELECT '$attachmentsTable', seq FROM sqlite_sequence WHERE name = 'entry_images';
    ''');
        await txn.execute('DROP TABLE entry_images;');
      });
    }
    if (oldVersion <= 6 && !await _tableExists(db, moodScaleTable)) {
      await _createMoodScaleLevelsTable(db);
      await db.execute('''
UPDATE $entriesTable SET ${EntryFields.mood} = ${EntryFields.mood} + 3
WHERE ${EntryFields.mood} IS NOT NULL
''');
      await MoodScaleDao.save(_legacyMoodScaleLevels(), executor: db);
    }
  }

  List<MoodScaleLevel> _legacyMoodScaleLevels() => [
        for (final (position, level) in MoodScalePreset.emoji.levels.indexed)
          level.copyWith(
            icon: ConfigProvider.instance
                .get<String>(Settings.moodIcons[position]),
          ),
      ];

  Future<bool> _tableExists(Database db, String name) async {
    final rows = await db.query('sqlite_master',
        columns: ['name'],
        where: "type = 'table' AND name = ?",
        whereArgs: [name]);
    return rows.isNotEmpty;
  }
}
