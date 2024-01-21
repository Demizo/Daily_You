import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:daily_you/file_layer.dart';
import 'package:daily_you/stats_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daily_you/models/entry.dart';
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
    if (usingExternalDb()) syncExternalDatabase();
    final dbPath = await getLogDatabasePath();

    _database = await openDatabase(dbPath, version: 1, onCreate: _createDB);
    return _database != null;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE $entriesTable (
  ${EntryFields.id} INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  ${EntryFields.text} TEXT NOT NULL,
  ${EntryFields.imgPath} TEXT,
  ${EntryFields.mood} INTEGER,
  ${EntryFields.timeCreate} DATETIME NOT NULL DEFAULT (DATETIME('now')),
  ${EntryFields.timeModified} DATETIME NOT NULL DEFAULT (DATETIME('now'))
)
''');
  }

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
      if (entry.imgPath != null) await deleteImg(entry.imgPath!);
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

  Future<Uint8List?> getImgBytes(String imageName) async {
    String basePath = await getImgDatabasePath();
    var bytes = await FileLayer.getFileBytes(basePath,
        name: imageName, useExternalPath: usingExternalImg());
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
    var imageFilePath = await FileLayer.createFile(
        await getImgDatabasePath(), newImageName, bytes,
        useExternalPath: usingExternalImg());
    if (imageFilePath == null) return null;
    if (Platform.isAndroid) {
      // Add image to media store
      MediaScanner.loadMedia(path: imageFilePath);
    }
    return newImageName;
  }

  Future<bool> deleteImg(String imageName) async {
    String basePath = await getImgDatabasePath();
    return await FileLayer.deleteFile(basePath,
        name: imageName, useExternalPath: usingExternalImg());
  }

  Future<String> getImgDatabasePath() async {
    if (!usingExternalImg()) {
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
    final rootImgPath = ConfigManager.instance.getField('externalImgUri');
    return rootImgPath;
  }

  Future<String> getLogDatabasePath() async {
    Directory basePath;
    if (Platform.isAndroid) {
      basePath = (await getExternalStorageDirectory())!;
      return Uri.file(join(basePath.path, 'daily_you.db')).toString();
    } else {
      basePath = await getApplicationSupportDirectory();
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }

      return join(basePath.path, 'daily_you.db');
    }
  }

  Future<bool> selectDatabaseLocation() async {
    var selectedDirectory = await FileLayer.pickDirectory();
    if (selectedDirectory == null) return false;
    // Check if DB exists in external directory
    var existingDbBytes =
        await FileLayer.getFileBytes(selectedDirectory, name: "daily_you.db");
    if (existingDbBytes != null) {
      //Overwrite internal DB
      var overwritten = await FileLayer.writeFileBytes(
          await getLogDatabasePath(), existingDbBytes);
      if (overwritten == false) return false;
    } else {
      // Export internal DB
      var bytes = await FileLayer.getFileBytes(await getLogDatabasePath());
      if (bytes == null) return false;
      var externalDbPath =
          await FileLayer.createFile(selectedDirectory, "daily_you.db", bytes);
      if (externalDbPath == null) return false;
    }
    // Use external DB
    await ConfigManager.instance.setField('externalDbUri', selectedDirectory);
    await ConfigManager.instance.setField('useExternalDb', true);
    // Open new database and update stats
    await _database!.close();
    await initDB();
    await StatsProvider.instance.updateStats();
    return true;
  }

  Future<bool> updateExternalDatabase() async {
    var bytes = await FileLayer.getFileBytes(await getLogDatabasePath());
    if (bytes == null) return false;
    return await FileLayer.writeFileBytes(
        ConfigManager.instance.getField('externalDbUri'), bytes,
        name: "daily_you.db");
  }

  Future<bool> syncExternalDatabase() async {
    // Check which file is newer
    if (await isExternalDbNewer()) {
      var bytes = await FileLayer.getFileBytes(
          ConfigManager.instance.getField('externalDbUri'),
          name: "daily_you.db");

      if (bytes != null) {
        //Overwrite internal DB
        return await FileLayer.writeFileBytes(
            await getLogDatabasePath(), bytes);
      } else {
        return false;
      }
    }
    return true;
  }

  Future<bool> isExternalDbNewer() async {
    // Get internal time
    String internalPath;
    Directory basePath;
    if (Platform.isAndroid) {
      basePath = (await getExternalStorageDirectory())!;
      internalPath = join(basePath.path, 'daily_you.db');
    } else {
      basePath = await getApplicationSupportDirectory();
      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }

      internalPath = join(basePath.path, 'daily_you.db');
    }
    var internalModifiedTime = await File(internalPath).lastModified();

    var externalModifiedTime = await FileLayer.getFileModifiedTime(
            ConfigManager.instance.getField('externalDbUri'),
            name: "daily_you.db") ??
        DateTime.now();

    return externalModifiedTime.isAfter(internalModifiedTime);
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
    await ConfigManager.instance.setField('externalImgUri', selectedDirectory);
    await ConfigManager.instance.setField('useExternalImg', true);
    return true;
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      return false;
    }

    final jsonFile = File(result.files.single.path!);
    final jsonContent = await jsonFile.readAsString();
    final jsonData = json.decode(jsonContent);

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

    return true;
  }

  Future<bool> exportImages() async {
    List<Entry> entries = await getAllEntries();

    String? saveDir = await FileLayer.pickDirectory();
    if (saveDir == null) return false;

    for (Entry entry in entries) {
      if (entry.imgPath == null) continue;
      var bytes = await getImgBytes(entry.imgPath!);
      if (bytes == null) continue;
      var newImageName =
          await FileLayer.createFile(saveDir, entry.imgPath!, bytes);
      if (newImageName == null) return false;
      if (Platform.isAndroid) {
        // Add image to media store
        MediaScanner.loadMedia(path: newImageName);
      }
    }

    return true;
  }

  Future<bool> importImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    for (XFile file in pickedFiles) {
      var imageFilePath = await FileLayer.createFile(
          await getImgDatabasePath(), file.name, await file.readAsBytes(),
          useExternalPath: usingExternalImg());
      if (imageFilePath == null) return false;
      if (Platform.isAndroid) {
        // Add image to media store
        MediaScanner.loadMedia(path: imageFilePath);
        await File(file.path).delete();
      }
    }
    return true;
  }

  Future<bool> exportToJson() async {
    //TODO Use file layer
    String? savePath = await FileLayer.pickDirectory();

    if (savePath == null) {
      return false;
    }

    final db = _database!;

    final List<Map<String, dynamic>> entries = await db.query('entries');

    final List<Map<String, dynamic>> jsonData = entries.map((entry) {
      return {
        'timeCreated': entry['time_create'],
        'timeModified': entry['time_modified'],
        'imgPath': entry['img_path'],
        'mood': entry['mood'],
        'text': entry['text'] ?? '',
      };
    }).toList();

    final jsonFile = File('$savePath/daily_you_logs.json');
    final jsonString = json.encode(jsonData);
    await jsonFile.create();
    await jsonFile.writeAsString(jsonString);
    return true;
  }

  Future<bool> importFromJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      return false;
    }

    final jsonFile = File(result.files.single.path!);
    final jsonContent = await jsonFile.readAsString();
    final jsonData = json.decode(jsonContent);

    final db = _database!;

    for (var entry in jsonData) {
      // Skip if the day already has an entry
      if (await getEntryForDate(DateTime.parse(entry['timeCreated'])) == null) {
        await db.insert('entries', {
          'text': entry['text'],
          'img_path': entry['imgPath'],
          'mood': entry['mood'],
          'time_create': entry['timeCreated'],
          'time_modified': entry['timeModified'],
        });
      }
    }
    return true;
  }
}
