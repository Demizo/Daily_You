import 'dart:io';

import 'package:flutter/services.dart';

class RegionalPreferences {
  static const MethodChannel _channel = MethodChannel('regional_preferences');

  /// Returns:
  ///   0–6  → Monday (0) … Sunday (6)
  ///   null → no preference is explicitly set
  static Future<int?> getFirstDayOfWeekIndex() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<int>('getFirstDayOfWeekIndex');
    }
    return null;
  }
}
