import 'dart:convert';
import 'dart:io';
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

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('daily_you.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getLogDatabasePath();

    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
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
    final db = await instance.database;

    final id = await db.insert(entriesTable, entry.toJson());

    return entry.copy(id: id);
  }

  Future<Entry?> getEntry(int id) async {
    final db = await instance.database;

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
    final db = await instance.database;

    final result =
        await db.query(entriesTable, orderBy: '${EntryFields.timeCreate} DESC');

    return result.map((json) => Entry.fromJson(json)).toList();
  }

  Future<List<Entry>> getAllEntriesSorted(String orderBy, String order) async {
    final db = await instance.database;

    final result = await db.query(entriesTable, orderBy: '$orderBy $order');

    return result.map((json) => Entry.fromJson(json)).toList();
  }

  Future<int> updateEntry(Entry entry) async {
    final db = await instance.database;

    return await db.update(
      entriesTable,
      entry.toJson(),
      where: '${EntryFields.id} = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;

    return await db.delete(
      entriesTable,
      where: '${EntryFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllEntries() async {
    final entries = await getAllEntries();
    for (Entry entry in entries) {
      await deleteEntryImage(entry.id!);
      await deleteEntry(entry.id!);
    }
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    db.close();
  }

  Future<String> getImgPath(String imageName) async {
    var basePath = await getImgDatabasePath();

    return '$basePath/$imageName';
  }

  Future<void> deleteEntryImage(int id) async {
    final entry = await getEntry(id);
    if (entry != null && entry.imgPath != null) {
      final path = '${await getImgDatabasePath()}/${entry.imgPath!}';
      if (await File(path).exists()) {
        await File(path).delete();
      }
    }
  }

  Future<String> getImgDatabasePath() async {
    if (ConfigManager.instance.getField('imgPath') == '') {
      Directory basePath;
      if (Platform.isAndroid) {
        basePath = (await getExternalStorageDirectory())!;
        basePath = Directory('${basePath.path}/Images');
      } else {
        basePath = await getApplicationSupportDirectory();
        basePath = Directory('${basePath.path}/Images');
      }

      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }

      return basePath.path;
    }
    final rootImgPath = ConfigManager.instance.getField('imgPath');
    return rootImgPath;
  }

  Future<String> getLogDatabasePath() async {
    Directory dbPath;
    var pathFromConfig = ConfigManager.instance.getField('dbPath');
    if (pathFromConfig != '' && pathFromConfig != null) {
      dbPath = Directory(pathFromConfig);
    } else {
      Directory basePath;
      if (Platform.isAndroid) {
        basePath = (await getExternalStorageDirectory())!;
      } else {
        basePath = await getApplicationSupportDirectory();
      }

      if (!basePath.existsSync()) {
        basePath.createSync(recursive: true);
      }
      dbPath = basePath;
    }
    return dbPath.path;
  }

  Future<bool> selectDatabaseLocation() async {
    final selectedDirectory = await getDirectoryPath();
    if (selectedDirectory.isNotEmpty && selectedDirectory != "/") {
      final newDbPath = '$selectedDirectory/daily_you.db';
      final oldDbPath = '${await getLogDatabasePath()}/daily_you.db';
      if (!await File(newDbPath).exists() && await File(oldDbPath).exists()) {
        await File(oldDbPath).copy(newDbPath);
      }
      await ConfigManager.instance.setField('dbPath', selectedDirectory);
      return true;
    } else {
      return false;
    }
  }

  void resetDatabaseLocation() async {
    await ConfigManager.instance.setField('dbPath', '');
  }

  Future<bool> selectImageFolder() async {
    final selectedDirectory = await getDirectoryPath();
    if (selectedDirectory.isNotEmpty && selectedDirectory != "/") {
      await ConfigManager.instance.setField('imgPath', selectedDirectory);
      return true;
    }
    return false;
  }

  void resetImageFolderLocation() async {
    await ConfigManager.instance.setField('imgPath', '');
  }

  Future<String> getDirectoryPath() async {
    Directory? selectedDirectory;
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      selectedDirectory = Directory(result);
    }

    return selectedDirectory?.path ?? '';
  }

  Future<String> getFilePath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
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

    final db = await instance.database;

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
    final imgDirectory = await EntriesDatabase.instance.getImgDatabasePath();

    String? saveDir = await FilePicker.platform.getDirectoryPath();
    if (saveDir == null) return false;

    for (Entry entry in entries) {
      if (entry.imgPath == null) continue;

      final imageFilePath = "$imgDirectory/${entry.imgPath}";

      File image = File(imageFilePath);
      if (await image.exists()) {
        final saveFilePath = "$saveDir/${entry.imgPath}";
        await image.copy(saveFilePath);

        if (Platform.isAndroid) {
          // Add image to media store
          MediaScanner.loadMedia(path: saveFilePath);
        }
      }
    }

    return true;
  }

  Future<bool> importImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    for (XFile file in pickedFiles) {
      final imgDirectory = await EntriesDatabase.instance.getImgDatabasePath();

      final imageFilePath = "$imgDirectory/${file.name}";
      await file.saveTo(imageFilePath);
      if (Platform.isAndroid) {
        // Add image to media store
        MediaScanner.loadMedia(path: imageFilePath);
      }
      // Delete picked file from cache
      await File(file.path).delete();
    }
    return true;
  }

  Future<bool> exportToJson() async {
    String? savePath = await getDirectoryPath();

    if (savePath.isEmpty) {
      return false;
    }

    final db = await instance.database;

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

    final db = await instance.database;

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
