// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:flutter/services.dart';

class ScreenProtection {
  static const MethodChannel _channel =
      MethodChannel('com.demizo.daily_you/security');

  static bool isAndroidOverride = false;

  static Future<bool> setSecureMode(bool enabled) async {
    if (!Platform.isAndroid && !isAndroidOverride) return false;
    try {
      final res =
          await _channel.invokeMethod<bool>('setSecureMode', {'secure': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateFromConfig() async {
    if (!Platform.isAndroid && !isAndroidOverride) return;
    final enabled = ConfigProvider.instance.get(Settings.screenProtection);
    await setSecureMode(enabled);
  }
}
