import 'dart:async';

import 'package:flutter/material.dart';
import 'package:daily_you/config_manager.dart';

class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  Future<void> initializeThemeFromConfig() async {
    final configTheme = ConfigManager().getField('theme');
    if (configTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (configTheme == 'light') {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  ThemeMode get currentThemeMode {
    return _themeMode;
  }
}
