import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/file_layer.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  AppDatabase._init();

  final Logger _logger = Logger('AppDatabase');

  /// True when a migration from external storage was attempted on the last
  /// [init] but failed.
  bool migrationFailed = false;

  static Database? _database;
  Database? get database => _database;

  String? _internalPath;

  Future<bool> init(
      {bool forceWithoutSync = false, bool allowMigration = true}) async {
    _internalPath = await getInternalPath();
    migrationFailed = false;
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
    final oldPath = join(oldDir.path, 'daily_you.db');
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

  Future<void> open() async {
    _database = await openDatabase(_internalPath!,
        version: 4, onCreate: _createDatabase, onUpgrade: _onUpgrade);

    await EntriesProvider.instance.load();
    await EntryImagesProvider.instance.load();
    await TemplatesProvider.instance.load();
    await TagsProvider.instance.load();
  }

  Future<void> close() async {
    final db = _database!;
    _database = null;
    db.close();
  }

  Future<bool> _validateSqliteDatabase(String path) async {
    try {
      final db = await openDatabase(path, readOnly: true);
      final result = await db.rawQuery("PRAGMA integrity_check;");
      await db.close();

      return result.first.values.first == "ok";
    } catch (_) {
      return false;
    }
  }

  bool usingExternalLocation() {
    return ConfigProvider.instance.get(ConfigKey.useExternalDb) ?? false;
  }

  Future<String> getInternalPath() async {
    final basePath = await getApplicationSupportDirectory();
    if (!basePath.existsSync()) basePath.createSync(recursive: true);
    return join(basePath.path, 'daily_you.db');
  }

  String getExternalPath() {
    return ConfigProvider.instance.get(ConfigKey.externalDbUri);
  }

  /// Return whether the app has permission to access the external location
  Future<bool> hasExternalLocationPermission() async {
    return FileLayer.hasPermission(getExternalPath());
  }

  /// Select an external database location. Returns whether a new location was set successfully.
  Future<bool> selectExternalLocation(Function(String) updateStatus) async {
    bool databaseUpdated = false;

    // Save old external path
    var oldExternalPath = getExternalPath();
    var oldUseExternalPath = usingExternalLocation();
    await _database!.close();

    try {
      var selectedDirectory = await FileLayer.pickDirectory();
      if (selectedDirectory != null) {
        await ConfigProvider.instance
            .set(ConfigKey.externalDbUri, selectedDirectory);
        await ConfigProvider.instance.set(ConfigKey.useExternalDb, true);

        // Sync with external folder
        databaseUpdated = await _syncWithExternalDatabase(forceOverwrite: true);
      }
    } catch (_) {
      // Do nothing
    }

    // Cleanup
    await open();
    if (!databaseUpdated) {
      // Restore state after failure
      await ConfigProvider.instance
          .set(ConfigKey.externalDbUri, oldExternalPath);
      await ConfigProvider.instance
          .set(ConfigKey.useExternalDb, oldUseExternalPath);
    } else {
      try {
        if (ImageStorage.instance.usingExternalLocation() &&
            await ImageStorage.instance.hasExternalLocationPermission()) {
          await ImageStorage.instance
              .syncImageFolder(true, updateStatus: updateStatus);
        }
      } catch (_) {
        // Do nothing
      }
    }
    return databaseUpdated;
  }

  void resetExternalLocation() async {
    await ConfigProvider.instance.set(ConfigKey.useExternalDb, false);
  }

  /// Overwrite the external database with local changes
  /// If an external database is not in use, no action is taken
  Future<void> updateExternalDatabase() async {
    if (usingExternalLocation()) {
      EasyDebounce.debounce("update-remote-database", Duration(seconds: 1),
          () async {
        // Create temporary export copy
        final tmpExport =
            "${_internalPath!}.export_${DateTime.now().millisecondsSinceEpoch}";
        database!.execute("VACUUM INTO '$tmpExport'");

        // Ensure export copy is valid
        if (!await _validateSqliteDatabase(tmpExport)) {
          await File(tmpExport).delete();
          return;
        }

        // Write to external location
        var bytes =
            await FileLayer.getFileBytes(tmpExport, useExternalPath: false);
        if (bytes == null) return;
        await FileLayer.writeFileBytes(getExternalPath(), bytes,
            name: "daily_you.db");

        await FileLayer.deleteFile(tmpExport, useExternalPath: false);
      });
    }
  }

  /// Pull in remote changes if the external database is newer or if forceOverwrite is set
  Future<bool> _syncWithExternalDatabase({bool forceOverwrite = false}) async {
    // Check if external database exists
    var externalExists =
        await FileLayer.exists(getExternalPath(), name: "daily_you.db");

    if (!externalExists) {
      var bytes =
          await FileLayer.getFileBytes(_internalPath!, useExternalPath: false);
      if (bytes == null) return false;

      // Export internal DB
      var externalDbPath =
          await FileLayer.createFile(getExternalPath(), "daily_you.db", bytes);
      return externalDbPath != null;
    } else if (forceOverwrite || await _isExternalDatabaseNewer()) {
      // Overwrite internal DB
      var externalBytes =
          await FileLayer.getFileBytes(getExternalPath(), name: "daily_you.db");
      if (externalBytes == null) return false;

      // Create temporary internal DB
      final temporaryInternalPath =
          "${_internalPath!}.${DateTime.now().millisecondsSinceEpoch}.tmp";
      final internalDirectory = dirname(temporaryInternalPath);
      final temporaryFileName = basename(temporaryInternalPath);
      await FileLayer.createFile(
          internalDirectory, temporaryFileName, externalBytes,
          useExternalPath: false);

      // Check that the new database is valid
      if (await FileLayer.exists(internalDirectory,
              name: temporaryFileName, useExternalPath: false) &&
          await _validateSqliteDatabase(temporaryInternalPath)) {
        // Replace internal database
        await FileLayer.renameFile(temporaryInternalPath, _internalPath!,
            useExternalPath: false);
      } else {
        // Delete temporary database
        await FileLayer.deleteFile(temporaryInternalPath,
            useExternalPath: false);
        return false;
      }
    }
    return true;
  }

  /// Return whether the external database is newer
  Future<bool> _isExternalDatabaseNewer() async {
    // Get internal time
    var internalModifiedTime = await FileLayer.getFileModifiedTime(
            _internalPath!,
            useExternalPath: false) ??
        DateTime.now();

    var externalModifiedTime = await FileLayer.getFileModifiedTime(
            getExternalPath(),
            name: "daily_you.db") ??
        internalModifiedTime;

    return externalModifiedTime.isAfter(internalModifiedTime);
  }

  // SQLite Database Actions

  Future _createDatabase(Database db, int version) async {
    _database = db;
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

    await TemplatesProvider.instance.createDefaultTemplates();

    await db.execute('''
CREATE TABLE $imagesTable (
    ${EntryImageFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntryImageFields.entryId} INTEGER NOT NULL,
    ${EntryImageFields.imgPath} TEXT NOT NULL,
    ${EntryImageFields.imgRank} INTEGER NOT NULL,
    ${EntryImageFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntryImageFields.entryId}) REFERENCES $entriesTable (id)
)
''');

    await _createTagTables(db);
    await TagsProvider.instance.createDefaultTags();

    await _createWelcomeEntry();
  }

  Future<void> _createWelcomeEntry() async {
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
        mood: 1,
        timeCreate: now,
        timeModified: now,
      ),
      skipUpdate: true,
    );

    final imageBytes =
        await rootBundle.load('assets/daily_you_First_Steps.webp');
    final imageName = await ImageStorage.instance.create(
      'daily_you_First_Steps.webp',
      imageBytes.buffer.asUint8List(),
      currTime: now,
    );
    if (imageName != null) {
      await EntryImagesProvider.instance.add(
        EntryImage(
          entryId: welcomeEntry.id,
          imgPath: imageName,
          imgRank: 0,
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

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
CREATE TABLE $imagesTable (
    ${EntryImageFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ${EntryImageFields.entryId} INTEGER NOT NULL,
    ${EntryImageFields.imgPath} TEXT NOT NULL,
    ${EntryImageFields.imgRank} INTEGER NOT NULL,
    ${EntryImageFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
    FOREIGN KEY (${EntryImageFields.entryId}) REFERENCES $entriesTable (id)
)
''');
      await db.transaction((txn) async {
        await txn.execute('''
-- Step 1: Insert the non-null imgPath entries into the imagesTable
INSERT INTO $imagesTable (${EntryImageFields.entryId}, ${EntryImageFields.imgPath}, ${EntryImageFields.imgRank}, ${EntryImageFields.timeCreate})
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
  }
}
