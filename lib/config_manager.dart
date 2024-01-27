import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ConfigManager {
  static final ConfigManager instance = ConfigManager._init();

  ConfigManager._init();

  String configFilePath = '';
  Map<String, dynamic> _config = {};
  final Map<String, dynamic> _defaultConfig = {
    'configVersion': '1',
    'theme': 'system',
    'useExternalDb': false,
    'externalDbUri': '',
    'useExternalImg': false,
    'externalImgUri': '',
    'startingDayOfWeek': 'sunday',
    'veryHappyIcon': '☺️',
    'happyIcon': '🙂',
    'neutralIcon': '😐',
    'sadIcon': '😕',
    'verySadIcon': '😔',
    'noMoodIcon': '?',
    'followSystemColor': true,
    'accentColor': 0xff01d3ef,
    'dailyReminders': false,
    'scheduledReminderHour': 12,
    'scheduledReminderMinute': 0,
  };

  static final moodValueFieldMapping = {
    2: 'veryHappyIcon',
    1: 'happyIcon',
    0: 'neutralIcon',
    -1: 'sadIcon',
    -2: 'verySadIcon',
  };

  static final ConfigManager _instance = ConfigManager._internal();

  factory ConfigManager() {
    return _instance;
  }

  ConfigManager._internal();

  // Create an empty config file
  Future<void> init() async {
    Directory dbPath;
    if (Platform.isAndroid) {
      dbPath = (await getExternalStorageDirectory())!;
    } else {
      dbPath = await getApplicationSupportDirectory();
    }
    configFilePath = join(dbPath.path, 'config.json');
    final configFile = File(configFilePath);
    if (!(await configFile.exists())) {
      await configFile.create();
      await configFile.writeAsString('{}');
    }
    await poplulateDefaults();
    await readFile();
  }

  Future<void> poplulateDefaults() async {
    await readFile();

    // Set default config data
    for (String key in _defaultConfig.keys) {
      if (!_config.containsKey(key)) _config[key] = _defaultConfig[key];
    }

    // Write the updated config data to the file
    await ConfigManager.instance.writeFile(_config);
  }

  // Read the contents of the config file
  Future<void> readFile() async {
    final configFile = File(configFilePath);
    if (await configFile.exists()) {
      final configFileContent = await configFile.readAsString();
      _config = json.decode(configFileContent);
    } else {
      _config = {};
    }
  }

  // Write the provided data to the config file
  Future<void> writeFile(Map<String, dynamic> data) async {
    final configFile = File(configFilePath);
    await configFile.writeAsString(json.encode(data));
    _config = data;
  }

  // Get a specific config field
  dynamic getField(String field) {
    return _config[field];
  }

  // Set a specific config field
  Future<void> setField(String field, dynamic value) async {
    _config[field] = value;
    await writeFile(_config);
  }
}
