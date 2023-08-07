import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:daily_you/models/entry.dart';
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
    Directory dbPath;
    var pathFromConfig = ConfigManager().getField('dbPath');
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

    final path = join(dbPath.path, filePath);
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

  Future close() async {
    final db = await instance.database;
    _database = null;
    db.close();
  }

  Future<String> getImgPath(String imageName) async {
    var basePath = await getImgDatabasePath();

    return '$basePath/$imageName';
  }

  Future<String> getImgDatabasePath() async {
    if (ConfigManager().getField('imgPath') == '') {
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
    final rootImgPath = ConfigManager().getField('imgPath');
    return rootImgPath;
  }

  void selectDatabaseLocation() async {
    final selectedDirectory = await getDirectoryPath();
    if (selectedDirectory.isNotEmpty) {
      ConfigManager().setField('dbPath', selectedDirectory);
    }
  }

  void resetDatabaseLocation() async {
    ConfigManager().setField('dbPath', '');
  }

  void selectImageFolder() async {
    final selectedDirectory = await getDirectoryPath();
    if (selectedDirectory.isNotEmpty) {
      ConfigManager().setField('imgPath', selectedDirectory);
    }
  }

  void resetImageFolderLocation() async {
    ConfigManager().setField('imgPath', '');
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
}
