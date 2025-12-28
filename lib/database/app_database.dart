import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  AppDatabase._init();

  static Database? _database;
  Database? get database => _database;

  String? _internalPath;

  Future<bool> init({bool forceWithoutSync = false}) async {
    _internalPath = await getInternalPath();
    await AppDatabase.instance.open();

    if (usingExternalLocation() && !forceWithoutSync) {
      if (await hasExternalLocationPermission()) {
        await _syncWithExternalDatabase();
      } else {
        return false;
      }
    }
    return true;
  }

  Future<void> open() async {
    _database = await openDatabase(_internalPath!,
        version: 3, onCreate: _createDatabase, onUpgrade: _onUpgrade);

    await EntriesProvider.instance.load();
    await EntryImagesProvider.instance.load();
    await TemplatesProvider.instance.load();
  }

  Future<void> close() async {
    final db = _database!;
    _database = null;
    db.close();
  }

  bool usingExternalLocation() {
    return ConfigProvider.instance.get(ConfigKey.useExternalDb) ?? false;
  }

  Future<String> getInternalPath() async {
    Directory basePath;
    if (Platform.isAndroid) {
      basePath = (await getExternalStorageDirectory())!;
    } else {
      basePath = await getApplicationSupportDirectory();
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }
    }
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
    try {
      var selectedDirectory = await FileLayer.pickDirectory();
      if (selectedDirectory == null) return false;

      // Save old external path
      var oldExternalPath = getExternalPath();
      var oldUseExternalPath = usingExternalLocation();

      await ConfigProvider.instance
          .set(ConfigKey.externalDbUri, selectedDirectory);
      await ConfigProvider.instance.set(ConfigKey.useExternalDb, true);
      // Sync with external folder
      var synced = await _syncWithExternalDatabase(forceOverwrite: true);
      if (synced) {
        // Open new database and update stats
        await _database!.close();
        await open();
        if (ImageStorage.instance.usingExternalLocation()) {
          await ImageStorage.instance
              .syncImageFolder(true, updateStatus: updateStatus);
        }
        return true;
      } else {
        // Restore state after failure
        await ConfigProvider.instance
            .set(ConfigKey.externalDbUri, oldExternalPath);
        await ConfigProvider.instance
            .set(ConfigKey.useExternalDb, oldUseExternalPath);
        return false;
      }
    } catch (_) {
      return false;
    }
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
        var bytes = await FileLayer.getFileBytes(_internalPath!,
            useExternalPath: false);
        if (bytes == null) return;
        await FileLayer.writeFileBytes(getExternalPath(), bytes,
            name: "daily_you.db");
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
      var externalBytes =
          await FileLayer.getFileBytes(getExternalPath(), name: "daily_you.db");
      if (externalBytes == null) return false;

      // Overwrite internal DB
      return await FileLayer.writeFileBytes(_internalPath!, externalBytes,
          useExternalPath: false);
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
  }
}
