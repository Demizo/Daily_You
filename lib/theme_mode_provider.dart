import 'dart:async';

import 'package:flutter/material.dart';
import 'package:daily_you/config_provider.dart';
import 'package:system_theme/system_theme.dart';

class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Color _accentColor = const Color(0xff01d3ef);
  Color get accentColor => _accentColor;

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  set accentColor(Color color) {
    ConfigProvider.instance.set(ConfigKey.accentColor, color.value);
    _accentColor = color;
  }

  void updateAccentColor() {
    if (ConfigProvider.instance.get(ConfigKey.followSystemColor)) {
      _accentColor = SystemTheme.accentColor.accent;
    } else {
      _accentColor = Color(ConfigProvider.instance.get(ConfigKey.accentColor));
    }
    notifyListeners();
  }

  Future<void> initializeThemeFromConfig() async {
    await SystemTheme.accentColor.load();
    SystemTheme.fallbackColor = _accentColor;
    if (ConfigProvider.instance.get(ConfigKey.followSystemColor)) {
      _accentColor = SystemTheme.accentColor.accent;
    } else {
      _accentColor = Color(ConfigProvider.instance.get(ConfigKey.accentColor));
    }

    final configTheme = ConfigProvider.instance.get(ConfigKey.theme);
    if (configTheme == 'dark' || configTheme == 'amoled') {
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
