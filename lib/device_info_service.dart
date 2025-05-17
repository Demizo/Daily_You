import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  int? androidSdk;
  String? model;

  Future<void> init() async {
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await plugin.androidInfo;
      androidSdk = androidInfo.version.sdkInt;
      model = androidInfo.model;
    }
  }
}
