import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/template.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'config_manager.dart';

class EntriesDatabase {
  static final EntriesDatabase instance = EntriesDatabase._init();

  static Database? _database;

  EntriesDatabase._init();

  Future<bool> initDB() async {
    if (usingExternalDb()) await syncDatabase();
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
    await createDefaultTemplates();
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
      await createDefaultTemplates();
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
  Future createDefaultTemplates() async {
    await createTemplate(Template(
        name: "High/Low",
        text: '''
### High
- 

### Low
- 
''',
        timeCreate: DateTime.now(),
        timeModified: DateTime.now()));
    await createTemplate(Template(
        name: "Quote",
        text: '''
### Quote of the day...
> ""
''',
        timeCreate: DateTime.now(),
        timeModified: DateTime.now()));
    await createTemplate(Template(
        name: "List",
        text: '''
- 
- 
- ''',
        timeCreate: DateTime.now(),
        timeModified: DateTime.now()));
  }

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

  Future<EntryImage> addImg(EntryImage entryImage) async {
    final db = _database!;

    final id = await db.insert(imagesTable, entryImage.toJson());
    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
    return entryImage.copy(id: id);
  }

  Future<int> removeImg(EntryImage entryImage) async {
    final db = _database!;

    // Delete image
    await deleteImg(entryImage.imgPath);

    // Remove from database
    final removedId = await db.delete(
      imagesTable,
      where: '${EntryImageFields.id} = ?',
      whereArgs: [entryImage.id],
    );

    if (usingExternalDb()) await updateExternalDatabase();
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

    if (usingExternalDb()) await updateExternalDatabase();
    return id;
  }

  Future<Uint8List?> getImgBytes(String imageName) async {
    // Fetch local copy if present
    var bytes = await FileLayer.getFileBytes(await getInternalImgDatabasePath(),
        name: imageName, useExternalPath: false);
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
    return bytes;
  }

  Future<String?> createImg(String imageName, Uint8List bytes) async {
    final currTime = DateTime.now();
    // Don't make a copy of files already in the folder
    if (await getImgBytes(imageName) != null) {
      return imageName;
    }
    final newImageName =
        "daily_you_${currTime.month}_${currTime.day}_${currTime.year}-${currTime.hour}.${currTime.minute}.${currTime.second}.jpg";
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
  Future<Entry> create(Entry entry) async {
    final db = _database!;

    final id = await db.insert(entriesTable, entry.toJson());
    await StatsProvider.instance.updateStats();
    if (usingExternalDb()) await updateExternalDatabase();
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

  Future<void> deleteAllEntries() async {
    final entries = await getAllEntries();
    for (Entry entry in entries) {
      var images = await getImagesForEntry(entry.id!);
      for (final image in images) {
        await removeImg(image);
      }
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
    return ConfigManager.instance.getField('useExternalDb') ?? false;
  }

  bool usingExternalImg() {
    return ConfigManager.instance.getField('useExternalImg') ?? false;
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
    final rootImgPath = ConfigManager.instance.getField('externalImgUri');
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
        await ConfigManager.instance.getField('externalDbUri'));
  }

  Future<bool> hasImgUriPermission() async {
    return FileLayer.hasPermission(await getExternalImgDatabasePath());
  }

  Future<bool> selectDatabaseLocation() async {
    StatsProvider.instance.updateSyncStats(0, 0);
    var selectedDirectory = await FileLayer.pickDirectory();
    if (selectedDirectory == null) return false;

    // Save old external path
    var oldExternalPath = ConfigManager.instance.getField('externalDbUri');
    var oldUseExternalPath = usingExternalDb();

    await ConfigManager.instance.setField('externalDbUri', selectedDirectory);
    await ConfigManager.instance.setField('useExternalDb', true);
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
      await ConfigManager.instance.setField('externalDbUri', oldExternalPath);
      await ConfigManager.instance
          .setField('useExternalDb', oldUseExternalPath);
      return false;
    }
  }

  Future<bool> updateExternalDatabase() async {
    var bytes = await FileLayer.getFileBytes(await getInternalDbPath(),
        useExternalPath: false);
    if (bytes == null) return false;
    return await FileLayer.writeFileBytes(
        ConfigManager.instance.getField('externalDbUri'), bytes,
        name: "daily_you.db");
  }

  Future<bool> syncDatabase({bool forceOverwrite = false}) async {
    var externalBytes = await FileLayer.getFileBytes(
        ConfigManager.instance.getField('externalDbUri'),
        name: "daily_you.db");

    if (externalBytes == null) {
      // Export internal DB
      var bytes = await FileLayer.getFileBytes(await getInternalDbPath(),
          useExternalPath: false);
      if (bytes == null) return false;
      var externalDbPath = await FileLayer.createFile(
          ConfigManager.instance.getField('externalDbUri'),
          "daily_you.db",
          bytes);
      return externalDbPath != null;
    } else if (forceOverwrite || await isExternalDbNewer()) {
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
            ConfigManager.instance.getField('externalDbUri'),
            name: "daily_you.db") ??
        DateTime.now();

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
      return await garbageCollectImages(entryImages);
    }
    return true;
  }

  Future<bool> garbageCollectImages(List<String> entryImages) async {
    // Get all internal photos
    var internalImages = Directory(await getInternalImgDatabasePath()).list();
    await for (FileSystemEntity fileEntity in internalImages) {
      if (fileEntity is File) {
        // Delete any that aren't used
        if (!entryImages.contains(basename(fileEntity.path))) {
          await File(fileEntity.path).delete();
        }
      }
    }
    return true;
  }

  void resetDatabaseLocation() async {
    await _database!.close();
    await ConfigManager.instance.setField('useExternalDb', false);
    await initDB();
    await StatsProvider.instance.updateStats();
  }

  Future<bool> selectImageFolder() async {
    var selectedDirectory = await FileLayer.pickDirectory();
    if (selectedDirectory == null) return false;

    // Save Old Settings
    var oldExternalImgUri = ConfigManager.instance.getField('externalImgUri');
    var oldUseExternalImg = usingExternalImg();

    await ConfigManager.instance.setField('externalImgUri', selectedDirectory);
    await ConfigManager.instance.setField('useExternalImg', true);
    var synced = await syncImageFolder(true);
    if (synced) {
      return true;
    } else {
      // Restore Settings
      await ConfigManager.instance
          .setField('externalImgUri', oldExternalImgUri);
      await ConfigManager.instance
          .setField('useExternalImg', oldUseExternalImg);
      return false;
    }
  }

  void resetImageFolderLocation() async {
    await ConfigManager.instance.setField('useExternalImg', false);
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

  Future<bool> importFromOneShot() async {
    StatsProvider.instance.updateSyncStats(0, 0);
    var selectedFile = await FileLayer.pickFile();
    if (selectedFile == null) return false;
    var bytes = await FileLayer.getFileBytes(selectedFile);
    if (bytes == null) return false;
    final jsonData = json.decode(utf8.decode(bytes.toList()));

    final happinessMapping = {
      "VERY_SAD": -2,
      "SAD": -1,
      "NEUTRAL": 0,
      "HAPPY": 1,
      "VERY_HAPPY": 2,
    };

    final db = _database!;

    for (var entry in jsonData) {
      final createdTimestamp = entry['created'];
      final createdDateTime =
          DateTime.fromMillisecondsSinceEpoch(createdTimestamp * 1000)
              .toIso8601String();
      final modifiedDateTime = DateTime.now().toUtc().toIso8601String();

      final happinessText = entry['happiness'];
      final mood = happinessMapping[happinessText];

      // Skip if the day already has an entry
      if (await getEntryForDate(DateTime.parse(createdDateTime)) == null) {
        await db.insert('entries', {
          'text': entry['textContent'],
          'img_path': entry['relativePath'],
          'mood': mood,
          'time_create': createdDateTime,
          'time_modified': modifiedDateTime,
        });
      }
    }
    if (usingExternalImg()) await syncImageFolder(true);
    return true;
  }

  Future<bool> exportImages() async {
    List<Entry> entries = await getAllEntries();

    String? saveDir = await FileLayer.pickDirectory();
    if (saveDir == null) return false;

    List<String> externalImages =
        await FileLayer.listFiles(saveDir, useExternalPath: true);

    for (Entry entry in entries) {
      var images = await getImagesForEntry(entry.id!);
      for (final image in images) {
        if (externalImages.contains(image.imgPath)) continue;
        var bytes = await getImgBytes(image.imgPath);
        if (bytes == null) continue;
        var newImageName =
            await FileLayer.createFile(saveDir, image.imgPath, bytes);
        if (newImageName == null) return false;
        if (Platform.isAndroid) {
          // Add image to media store
          MediaScanner.loadMedia(path: newImageName);
        }
      }
    }

    return true;
  }

  Future<bool> importImages() async {
    StatsProvider.instance.updateSyncStats(0, 0);
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    List<String> externalImages = List.empty(growable: true);
    if (usingExternalImg()) {
      externalImages.addAll(await FileLayer.listFiles(
          await getExternalImgDatabasePath(),
          useExternalPath: true));
    }
    List<String> internalImages = await FileLayer.listFiles(
        await getInternalImgDatabasePath(),
        useExternalPath: false);

    int imported = 0;
    for (XFile file in pickedFiles) {
      if (!internalImages.contains(file.name)) {
        var imageFilePath = await FileLayer.createFile(
            await getInternalImgDatabasePath(),
            file.name,
            await file.readAsBytes(),
            useExternalPath: false);
        if (usingExternalImg() && !externalImages.contains(file.name)) {
          await FileLayer.createFile(await getExternalImgDatabasePath(),
              file.name, await file.readAsBytes(),
              useExternalPath: true);
        }
        if (imageFilePath == null) return false;
        if (Platform.isAndroid) {
          // Add image to media store
          MediaScanner.loadMedia(path: imageFilePath);
          await File(file.path).delete();
        }
      }

      imported += 1;
      StatsProvider.instance.updateSyncStats(pickedFiles.length, imported);
    }
    return true;
  }

  Future<bool> exportToJson() async {
    String? savePath = await FileLayer.pickDirectory();
    if (savePath == null) return false;

    final db = _database!;

    final List<Map<String, dynamic>> entries = await db.query('entries');

    List<Map<String, dynamic>> jsonList = [];

    for (var entry in entries) {
      // Query to get images for the current entry
      List<Map<String, dynamic>> images = await db.query(
        imagesTable,
        where: '${EntryImageFields.entryId} = ?',
        whereArgs: [entry[EntryFields.id]],
      );

      // Convert images to a list of maps
      List<Map<String, dynamic>> imageList = images
          .map((img) => {
                'imgPath': img[EntryImageFields.imgPath],
                'imgRank': img[EntryImageFields.imgRank],
                'timeCreated': img[EntryImageFields.timeCreate],
              })
          .toList();

      // Structure the entry
      Map<String, dynamic> jsonEntry = {
        'timeCreated': entry[EntryFields.timeCreate],
        'timeModified': entry[EntryFields.timeModified],
        'images': imageList,
        'mood': entry[EntryFields.mood],
        'text': entry[EntryFields.text] ?? '',
      };

      jsonList.add(jsonEntry);
    }

    final jsonString = json.encode(jsonList);
    final currTime = DateTime.now();
    final exportedJsonName =
        "daily_you_logs_${currTime.month}_${currTime.day}_${currTime.year}.json";
    return await FileLayer.createFile(savePath, exportedJsonName,
            Uint8List.fromList(utf8.encode(jsonString))) !=
        null;
  }

  Future<bool> importFromJson() async {
    StatsProvider.instance.updateSyncStats(0, 0);
    var selectedFile = await FileLayer.pickFile();
    if (selectedFile == null) return false;
    var bytes = await FileLayer.getFileBytes(selectedFile);
    if (bytes == null) return false;
    final jsonData = json.decode(utf8.decode(bytes.toList()));

    final db = _database!;

    for (var entry in jsonData) {
      // Skip if the day already has an entry
      if (await getEntryForDate(DateTime.parse(entry['timeCreated'])) == null) {
        int id = await db.insert(entriesTable, {
          'text': entry['text'],
          'mood': entry['mood'],
          'time_create': entry['timeCreated'],
          'time_modified': entry['timeModified'],
        });
        // Support old imgPath field
        if (entry['imgPath'] != null) {
          EntryImage image = EntryImage(
              entryId: id,
              imgPath: entry['imgPath'],
              imgRank: 0,
              timeCreate: DateTime.now());
          await addImg(image);
        }
        // Import images
        if (entry['images'] != null) {
          for (var img in entry['images']) {
            await db.insert(imagesTable, {
              EntryImageFields.entryId: id,
              EntryImageFields.imgPath: img['imgPath'],
              EntryImageFields.imgRank: img['imgRank'],
              EntryImageFields.timeCreate: img['timeCreated'],
            });
          }
        }
      }
    }
    if (usingExternalImg()) await syncImageFolder(true);
    return true;
  }
}
