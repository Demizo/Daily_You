import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  int? androidSdk;
  String? model;
  PackageInfo? appInfo;
  bool? supportsBiometrics;

  Future<void> init() async {
    final plugin = DeviceInfoPlugin();
    appInfo = await PackageInfo.fromPlatform();
    final auth = LocalAuthentication();

    if (Platform.isAndroid) {
      final androidInfo = await plugin.androidInfo;
      androidSdk = androidInfo.version.sdkInt;
      model = androidInfo.model;
      supportsBiometrics = await auth.canCheckBiometrics;
    }
  }
}
