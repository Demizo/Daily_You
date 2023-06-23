import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ConfigManager {
  String configFilePath = '';
  Map<String, dynamic> _config = {};

  static final ConfigManager _instance = ConfigManager._internal();

  factory ConfigManager() {
    return _instance;
  }

  ConfigManager._internal();

  // Create an empty config file
  Future<void> init() async {
    final dbPath = await getApplicationSupportDirectory();
    configFilePath = join(dbPath.path, 'config.json');
    final configFile = File(configFilePath);
    if (!(await configFile.exists())) {
      await configFile.create();
      await configFile.writeAsString('{}');

      readFile();

      // Set default config data
      _config['theme'] = 'system';
      _config['dbPath'] = '';
      _config['imgPath'] = '';

      // Write the updated config data to the file
      await ConfigManager().writeFile(_config);
    }
    await readFile();
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
  void setField(String field, String value) {
    _config[field] = value;
    writeFile(_config);
  }
}
