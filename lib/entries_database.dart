// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/file_bytes_cache.dart';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:schedulers/schedulers.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class EntriesDatabase {
  static final EntriesDatabase instance = EntriesDatabase._init();

  static Database? _database;

  final FileBytesCache imageCache =
      FileBytesCache(maxCacheSize: 100 * 1024 * 1024);
  final imgFetchScheduler = ParallelScheduler(5);

  EntriesDatabase._init();

  Future<bool> initDB({bool forceWithoutSync = false}) async {
    if (usingExternalDb() && !forceWithoutSync) {
      if (await hasDbUriPermission()) {
        await syncDatabase();
      } else {
        return false;
      }
    }

    final dbPath = await getInternalDbPath();

    _database = await openDatabase(dbPath,
        version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
    return _database != null;
  }

  Future _createDB(Database db, int version) async {
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
    ${EntryImageFields.imgPath} TEXT NOY NULL,
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
    ${EntryImageFields.imgPath} TEXT NOY NULL,
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

  // Template Methods

  Future<Template> createTemplate(Template template) async {
    final db = _database!;

    final id = await db.insert(templatesTable, template.toJson());
    if (usingExternalDb()) await updateExternalDatabase();
    return template.copy(id: id);
  }

  Future<Template?> getTemplate(int id) async {
    final db = _database!;

    final maps = await db.query(
      templatesTable,
      columns: TemplatesFields.values,
      where: '${TemplatesFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Template.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Template>> getAllTemplates() async {
    final db = _database!;

    final result =
        await db.query(templatesTable, orderBy: '${TemplatesFields.name} DESC');

    return result.map((json) => Template.fromJson(json)).toList();
  }

  Future<int> updateTemplate(Template template) async {
    final db = _database!;

    final id = await db.update(
      templatesTable,
      template.toJson(),
      where: '${TemplatesFields.id} = ?',
      whereArgs: [template.id],
    );

    if (usingExternalDb()) await updateExternalDatabase();
    return id;
  }

  Future<int> deleteTemplate(int id) async {
    final db = _database!;

    final removedId = await db.delete(
      templatesTable,
      where: '${TemplatesFields.id} = ?',
      whereArgs: [id],
    );

    if (usingExternalDb()) await updateExternalDatabase();
    return removedId;
  }

  // Image Methods
  Future<List<EntryImage>> getAllEntryImages() async {
    final db = _database!;

    final result = await db.query(imagesTable,
        orderBy: '${EntryImageFields.imgRank} DESC');

    return result.map((json) => EntryImage.fromJson(json)).toList();
  }

  Future<List<EntryImage>> getImagesForEntry(int entryId) async {
    final db = _database!;

    List<EntryImage> entryImages = List.empty(growable: true);

    final maps = await db.query(imagesTable,
        where: '${EntryImageFields.entryId} = ?',
        whereArgs: [entryId],
        orderBy: '${EntryImageFields.imgRank} DESC');

    for (final map in maps) {
      entryImages.add(EntryImage.fromJson(map));
    }

    return entryImages;
  }

  Future<EntryImage> addImg(EntryImage entryImage,
      {updateStatsAndSync = true}) async {
    final db = _database!;

    final id = await db.insert(imagesTable, entryImage.toJson());

    if (updateStatsAndSync) {
      await StatsProvider.instance.updateStats();
      if (usingExternalDb()) await updateExternalDatabase();
    }

    return entryImage.copy(id: id);
  }

  Future<int> removeImg(EntryImage entryImage, {updateData = true}) async {
    final db = _database!;

    // Delete image
    await deleteImg(entryImage.imgPath);

    // Remove from database
    final removedId = await db.delete(
      imagesTable,
      where: '${EntryImageFields.id} = ?',
      whereArgs: [entryImage.id],
    );
    if (updateData) {
      await StatsProvider.instance.updateStats();
      if (usingExternalDb()) await updateExternalDatabase();
    }
    return removedId;
  }

  Future<int> updateImg(EntryImage image) async {
    final db = _database!;

    final id = await db.update(
      imagesTable,
      image.toJson(),
      where: '${EntryImageFields.id} = ?',
      whereArgs: [image.id],
    );
    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
    return id;
  }

  Future<Uint8List?> getImgBytes(String imageName) async {
    // Fetch cache copy if present
    var bytes = imageCache.get(imageName);
    if (bytes != null) {
      return bytes;
    }
    // Fetch local copy if present
    var internalDir = await getInternalImgDatabasePath();
    bytes = await imgFetchScheduler
        .run(() => FileLayer.getFileBytes(internalDir,
            name: imageName, useExternalPath: false))
        .result;
    // Attempt to fetch file externally
    if (bytes == null && usingExternalImg()) {
      // Get and cache external image
      bytes = await FileLayer.getFileBytes(await getExternalImgDatabasePath(),
          name: imageName, useExternalPath: true);
      if (bytes != null) {
        await FileLayer.createFile(
            await getInternalImgDatabasePath(), imageName, bytes,
            useExternalPath: false);
      }
    }
    if (bytes != null) {
      imageCache.put(imageName, bytes);
    }
    return bytes;
  }

  Future<String?> createImg(String imageName, Uint8List bytes) async {
    final currTime = DateTime.now();
    // Don't make a copy of files already in the folder
    if (await getImgBytes(imageName) != null) {
      return imageName;
    }

    var newImageName =
        "daily_you_${currTime.month}_${currTime.day}_${currTime.year}-${currTime.hour}.${currTime.minute}.${currTime.second}.jpg";

    // Ensure unique name
    int index = 1;
    while (await FileLayer.exists(await getInternalImgDatabasePath(),
        name: newImageName, useExternalPath: false)) {
      newImageName =
          "daily_you_${currTime.month}_${currTime.day}_${currTime.year}-${currTime.hour}.${currTime.minute}.${currTime.second}_$index.jpg";
      index += 1;
    }

    if (usingExternalImg()) {
      FileLayer.createFile(
          await getExternalImgDatabasePath(), newImageName, bytes,
          useExternalPath: true); //Background
    }
    var imageFilePath = await FileLayer.createFile(
        await getInternalImgDatabasePath(), newImageName, bytes,
        useExternalPath: false);
    if (imageFilePath == null) return null;
    if (Platform.isAndroid) {
      // Add image to media store
      MediaScanner.loadMedia(path: imageFilePath);
    }
    return newImageName;
  }

  Future<bool> deleteImg(String imageName) async {
    // Delete remote
    if (usingExternalImg()) {
      await FileLayer.deleteFile(await getExternalImgDatabasePath(),
          name: imageName, useExternalPath: true);
    }
    // Delete local
    return await FileLayer.deleteFile(await getInternalImgDatabasePath(),
        name: imageName, useExternalPath: false);
  }

  // Entry Methods
  Future<Entry> addEntry(Entry entry, {updateStatsAndSync = true}) async {
    final db = _database!;

    final id = await db.insert(entriesTable, entry.toJson());

    if (updateStatsAndSync) {
      await StatsProvider.instance.updateStats();
      if (usingExternalDb()) await updateExternalDatabase();
    }
    return entry.copy(id: id);
  }

  Future<Entry?> getEntry(int id) async {
    final db = _database!;

    final maps = await db.query(
      entriesTable,
      columns: EntryFields.values,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Entry.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Entry?> getEntryForDate(DateTime date) async {
    final entries = await getAllEntries();

    //Search each entry for one on the date
    for (var entry in entries) {
      if (entry.timeCreate.day == date.day &&
          entry.timeCreate.month == date.month &&
          entry.timeCreate.year == date.year) {
        return entry;
      }
    }

    return null;
  }

  Future<List<Entry>> getAllEntries() async {
    final db = _database!;

    final result =
        await db.query(entriesTable, orderBy: '${EntryFields.timeCreate} DESC');

    return result.map((json) => Entry.fromJson(json)).toList();
  }

  Future<List<Entry>> getAllEntriesSorted(String orderBy, String order) async {
    final db = _database!;

    final result = await db.query(entriesTable, orderBy: '$orderBy $order');

    return result.map((json) => Entry.fromJson(json)).toList();
  }

  Future<int> updateEntry(Entry entry) async {
    final db = _database!;

    final id = await db.update(
      entriesTable,
      entry.toJson(),
      where: '${EntryFields.id} = ?',
      whereArgs: [entry.id],
    );
    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
    return id;
  }

  Future<int> deleteEntry(int id) async {
    final db = _database!;

    final removedId = await db.delete(
      entriesTable,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );
    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
    return removedId;
  }

  Future<void> deleteAllEntries(Function(String) updateStatus) async {
    updateStatus("0%");
    final entries = await getAllEntries();
    var processedEntries = 0;
    for (Entry entry in entries) {
      var images = await getImagesForEntry(entry.id!);
      for (final image in images) {
        // Don't update data until everything is deleted
        await removeImg(image, updateData: false);
      }
      processedEntries += 1;
      updateStatus("${((processedEntries / entries.length) * 100).round()}%");
    }
    final db = _database!;

    await db.delete(
      entriesTable,
    );

    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
  }

  Future close() async {
    final db = _database!;
    _database = null;
    db.close();
  }

  bool usingExternalDb() {
    return ConfigProvider.instance.get(ConfigKey.useExternalDb) ?? false;
  }

  bool usingExternalImg() {
    return ConfigProvider.instance.get(ConfigKey.useExternalImg) ?? false;
  }

  Future<String> getInternalImgDatabasePath() async {
    Directory basePath;
    if (Platform.isAndroid) {
      basePath = (await getExternalStorageDirectory())!;
      basePath = Directory('${basePath.path}/Images');
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }
      return basePath.path;
    } else {
      basePath = await getApplicationSupportDirectory();
      basePath = Directory('${basePath.path}/Images');
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }

      return basePath.path;
    }
  }

  Future<String> getExternalImgDatabasePath() async {
    final rootImgPath = ConfigProvider.instance.get(ConfigKey.externalImgUri);
    return rootImgPath;
  }

  Future<String> getInternalDbPath() async {
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

  // Ensure external folders can be accessed if in use
  Future<bool> hasDbUriPermission() async {
    return FileLayer.hasPermission(
        await ConfigProvider.instance.get(ConfigKey.externalDbUri));
  }

  Future<bool> hasImgUriPermission() async {
    return FileLayer.hasPermission(await getExternalImgDatabasePath());
  }

  Future<bool> selectDatabaseLocation() async {
    StatsProvider.instance.updateSyncStats(0, 0);
    var selectedDirectory = await FileLayer.pickDirectory();
    if (selectedDirectory == null) return false;

    // Save old external path
    var oldExternalPath = ConfigProvider.instance.get(ConfigKey.externalDbUri);
    var oldUseExternalPath = usingExternalDb();

    await ConfigProvider.instance
        .set(ConfigKey.externalDbUri, selectedDirectory);
    await ConfigProvider.instance.set(ConfigKey.useExternalDb, true);
    // Sync with external folder
    var synced = await syncDatabase(forceOverwrite: true);
    if (synced) {
      // Open new database and update stats
      await _database!.close();
      await initDB();
      await StatsProvider.instance.updateStats();
      if (usingExternalImg()) await syncImageFolder(true);
      return true;
    } else {
      // Restore state after failure
      await ConfigProvider.instance
          .set(ConfigKey.externalDbUri, oldExternalPath);
      await ConfigProvider.instance
          .set(ConfigKey.useExternalDb, oldUseExternalPath);
      return false;
    }
  }

  Future<bool> updateExternalDatabase() async {
    var bytes = await FileLayer.getFileBytes(await getInternalDbPath(),
        useExternalPath: false);
    if (bytes == null) return false;
    return await FileLayer.writeFileBytes(
        ConfigProvider.instance.get(ConfigKey.externalDbUri), bytes,
        name: "daily_you.db");
  }

  Future<bool> syncDatabase({bool forceOverwrite = false}) async {
    // Check if external database exists
    var externalExists = await FileLayer.exists(
        ConfigProvider.instance.get(ConfigKey.externalDbUri),
        name: "daily_you.db");

    if (!externalExists) {
      var bytes = await FileLayer.getFileBytes(await getInternalDbPath(),
          useExternalPath: false);
      if (bytes == null) return false;

      // Export internal DB
      var externalDbPath = await FileLayer.createFile(
          ConfigProvider.instance.get(ConfigKey.externalDbUri),
          "daily_you.db",
          bytes);
      return externalDbPath != null;
    } else if (forceOverwrite || await isExternalDbNewer()) {
      var externalBytes = await FileLayer.getFileBytes(
          ConfigProvider.instance.get(ConfigKey.externalDbUri),
          name: "daily_you.db");
      if (externalBytes == null) return false;

      // Overwrite internal DB
      return await FileLayer.writeFileBytes(
          await getInternalDbPath(), externalBytes,
          useExternalPath: false);
    }
    return true;
  }

  Future<bool> isExternalDbNewer() async {
    // Get internal time
    var internalModifiedTime = await FileLayer.getFileModifiedTime(
            await getInternalDbPath(),
            useExternalPath: false) ??
        DateTime.now();

    var externalModifiedTime = await FileLayer.getFileModifiedTime(
            ConfigProvider.instance.get(ConfigKey.externalDbUri),
            name: "daily_you.db") ??
        internalModifiedTime;

    return externalModifiedTime.isAfter(internalModifiedTime);
  }

  Future<bool> syncImageFolder(bool garbageCollect) async {
    StatsProvider.instance.updateSyncStats(0, 0);
    List<String> entryImages = List.empty(growable: true);

    List<String> externalImages = await FileLayer.listFiles(
        await getExternalImgDatabasePath(),
        useExternalPath: true);
    List<String> internalImages = await FileLayer.listFiles(
        await getInternalImgDatabasePath(),
        useExternalPath: false);

    List<Entry> entries = await getAllEntries();
    int syncedEntries = 0;
    for (Entry entry in entries) {
      var images = await getImagesForEntry(entry.id!);
      for (final image in images) {
        var entryImg = image.imgPath;

        entryImages.add(entryImg);

        // Export
        if (internalImages.contains(entryImg) &&
            !externalImages.contains(entryImg)) {
          var bytes = await FileLayer.getFileBytes(
              await getInternalImgDatabasePath(),
              name: entryImg,
              useExternalPath: false);
          await FileLayer.createFile(
              await getExternalImgDatabasePath(), entryImg, bytes!,
              useExternalPath: true);
        }

        // Import
        if (externalImages.contains(entryImg) &&
            !internalImages.contains(entryImg)) {
          var bytes = await FileLayer.getFileBytes(
              await getExternalImgDatabasePath(),
              name: entryImg,
              useExternalPath: true);
          await FileLayer.createFile(
              await getInternalImgDatabasePath(), entryImg, bytes!,
              useExternalPath: false);
        }
        syncedEntries += 1;
        StatsProvider.instance.updateSyncStats(entries.length, syncedEntries);
      }
    }

    if (garbageCollect) {
      return await garbageCollectImages();
    }
    return true;
  }

  Future<bool> garbageCollectImages() async {
    var entryImages = await getAllEntryImages();
    var entryImageNames =
        entryImages.map((entryImage) => entryImage.imgPath).toList();
    // Get all internal photos
    var internalImages = Directory(await getInternalImgDatabasePath()).list();
    await for (FileSystemEntity fileEntity in internalImages) {
      if (fileEntity is File) {
        // Delete any that aren't used
        if (!entryImageNames.contains(basename(fileEntity.path))) {
          await File(fileEntity.path).delete();
        }
      }
    }
    return true;
  }

  void resetDatabaseLocation() async {
    await _database!.close();
    await ConfigProvider.instance.set(ConfigKey.useExternalDb, false);
    await initDB();
    await StatsProvider.instance.updateStats();
  }

  Future<bool> selectImageFolder() async {
    var selectedDirectory = await FileLayer.pickDirectory();
    if (selectedDirectory == null) return false;

    // Save Old Settings
    var oldExternalImgUri =
        ConfigProvider.instance.get(ConfigKey.externalImgUri);
    var oldUseExternalImg = usingExternalImg();

    await ConfigProvider.instance
        .set(ConfigKey.externalImgUri, selectedDirectory);
    await ConfigProvider.instance.set(ConfigKey.useExternalImg, true);
    var synced = await syncImageFolder(true);
    if (synced) {
      return true;
    } else {
      // Restore Settings
      await ConfigProvider.instance
          .set(ConfigKey.externalImgUri, oldExternalImgUri);
      await ConfigProvider.instance
          .set(ConfigKey.useExternalImg, oldUseExternalImg);
      return false;
    }
  }

  void resetImageFolderLocation() async {
    await ConfigProvider.instance.set(ConfigKey.useExternalImg, false);
  }

  Future<String> getFilePath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final filePath = result.files.single.path;
      return filePath ?? '';
    }

    return '';
  }

  Future<bool> backupToZip(
      BuildContext context, void Function(String) updateStatus) async {
    String? savePath = await FileLayer.pickDirectory();
    if (savePath == null) return false;

    var tempDir = await getTemporaryDirectory();

    final exportedZipName =
        "daily_you_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip";

    // Create archive
    updateStatus(AppLocalizations.of(context)!.creatingBackupStatus("0"));
    var rxPort = ReceivePort();

    rxPort.listen((data) {
      var percent = data as double;
      updateStatus(AppLocalizations.of(context)!
          .creatingBackupStatus("${percent.round()}"));
    });

    await compute(
      encodeArchive,
      [
        join(tempDir.path, exportedZipName),
        await getInternalDbPath(),
        await getInternalImgDatabasePath(),
        rxPort.sendPort
      ],
    );

    rxPort.close();

    // Save archive
    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));

    final archiveSize = await FileLayer.getFileSize(tempDir.path,
        name: exportedZipName, useExternalPath: false);
    if (archiveSize == null || archiveSize == 0) return false;

    var readStream = await FileLayer.readFileStream(tempDir.path,
        name: exportedZipName, useExternalPath: false);
    if (readStream == null) return false;
    var writeStream =
        await FileLayer.openFileWriteStream(savePath, exportedZipName);
    if (writeStream == null) return false;

    var transferredSize = 0;

    await for (List<int> chunk in readStream) {
      await FileLayer.writeFileWriteStreamChunk(
          writeStream, Uint8List.fromList(chunk));
      transferredSize += chunk.length;
      var percent = (transferredSize / archiveSize) * 100;
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    }
    await FileLayer.closeFileWriteStream(writeStream);

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    await File(join(tempDir.path, exportedZipName)).delete();

    return true;
  }

  Future<bool> restoreFromZip(
      BuildContext context, void Function(String) updateStatus) async {
    var importSuccessful = true;

    String? archive = await FileLayer.pickFile(
        allowedExtensions: ['zip'], mimeTypes: ['application/zip']);

    if (archive == null) return false;

    var tempDir = await getTemporaryDirectory();

    final tempZipName = "temp_backup.zip";

    // Import archive
    updateStatus(AppLocalizations.of(context)!.tranferStatus("0"));

    final archiveSize = await FileLayer.getFileSize(archive);
    if (archiveSize == null || archiveSize == 0) return false;

    var readStream =
        await FileLayer.readFileStream(archive, useExternalPath: true);
    if (readStream == null) return false;
    var writeStream = await FileLayer.openFileWriteStream(
        tempDir.path, tempZipName,
        useExternalPath: false);
    if (writeStream == null) return false;

    var transferredSize = 0;

    await for (List<int> chunk in readStream) {
      await FileLayer.writeFileWriteStreamChunk(
          writeStream, Uint8List.fromList(chunk));
      transferredSize += chunk.length;
      var percent = (transferredSize / archiveSize) * 100;
      updateStatus(
          AppLocalizations.of(context)!.tranferStatus("${percent.round()}"));
    }
    await FileLayer.closeFileWriteStream(writeStream);

    // Restore archive
    final restoreFolder = Directory(join(tempDir.path, "Restore"));
    if (await restoreFolder.exists() == false) {
      await restoreFolder.create();
    }

    updateStatus(AppLocalizations.of(context)!.restoringBackupStatus("0"));

    var rxPort = ReceivePort();

    rxPort.listen((data) {
      var percent = data as double;
      updateStatus(AppLocalizations.of(context)!
          .restoringBackupStatus("${percent.round()}"));
    });

    await compute(decodeArchive,
        [join(tempDir.path, tempZipName), restoreFolder.path, rxPort.sendPort]);

    rxPort.close();

    final tempDb = File(join(restoreFolder.path, 'daily_you.db'));
    if (await tempDb.exists()) {
      // Import database
      await _database!.close();
      await File(await getInternalDbPath())
          .writeAsBytes(await tempDb.readAsBytes());
      await initDB();

      // Import images. These will be garbage collected after import
      if (await Directory(join(restoreFolder.path, "Images")).exists()) {
        // Also show cleanup status here since images may take awhile
        updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
        var files = Directory(join(restoreFolder.path, "Images")).list();
        final internalImagePath = await getInternalImgDatabasePath();
        await for (FileSystemEntity fileEntity in files) {
          if (fileEntity is File) {
            await File(join(internalImagePath, basename(fileEntity.path)))
                .writeAsBytes(await fileEntity.readAsBytes());
          }
        }
        if (usingExternalImg()) await syncImageFolder(false);
        await garbageCollectImages();
      }

      await StatsProvider.instance.updateStats();
    } else {
      importSuccessful = false;
    }

    // Delete temp files
    updateStatus(AppLocalizations.of(context)!.cleanUpStatus);
    await File(join(tempDir.path, tempZipName)).delete();
    if (await restoreFolder.exists()) {
      await restoreFolder.delete(recursive: true);
    }

    return importSuccessful;
  }

  Future<void> encodeArchive(List<dynamic> args) async {
    SendPort sendPort = args[3];
    var encoder = ZipFileEncoder();
    encoder.createWithStream(OutputFileStream(args[0]));
    await encoder.addFile(File(args[1]));
    await encoder.addDirectory(Directory(args[2]), onProgress: (progress) {
      sendPort.send(progress * 100);
    });
    await encoder.close();
  }

  Future<void> decodeArchive(List<dynamic> args) async {
    SendPort sendPort = args[2];
    var decoder = ZipDecoder().decodeStream(InputFileStream(args[0]));

    // Track number of files for progress indication
    var totalFileCount = decoder.numberOfFiles();
    var processedFileCount = 0;

    for (final entry in decoder) {
      if (entry.isFile) {
        final bytes = entry.readBytes();
        if (bytes == null) continue;
        final parent = Directory(File(join(args[1], entry.name)).parent.path);
        if (await parent.exists() == false) {
          await parent.create(recursive: true);
        }
        await File(join(args[1], entry.name)).writeAsBytes(bytes);

        // Updates status
        processedFileCount += 1;
        sendPort.send((processedFileCount / totalFileCount) * 100);
      } else {
        await Directory(join(args[1], entry.name)).create(recursive: true);
      }
    }
  }
}
