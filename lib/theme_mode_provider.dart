// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:daily_you/config_provider.dart';
import 'package:system_theme/system_theme.dart';

class ThemeModeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Color _accentColor = const Color(0xff62A0EA);
  Color get accentColor => _accentColor;
  bool get usingSystemColor =>
      ConfigProvider.instance.get(Settings.followSystemColor);

  set themeMode(ThemeMode value) {
    _themeMode = value;
    notifyListeners();
  }

  static ThemeMode modeFor(String theme) => switch (theme) {
        'light' => ThemeMode.light,
        'dark' || 'amoled' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setTheme(String theme) {
    themeMode = modeFor(theme);
    return ConfigProvider.instance.set(Settings.theme, theme);
  }

  set accentColor(Color color) {
    ConfigProvider.instance.set(Settings.accentColor, color.toARGB32());
    _accentColor = color;
  }

  void updateAccentColor() {
    if (ConfigProvider.instance.get(Settings.followSystemColor)) {
      _accentColor = SystemTheme.accentColor.accent;
    } else {
      _accentColor = Color(ConfigProvider.instance.get(Settings.accentColor));
    }
    notifyListeners();
  }

  Future<void> initializeThemeFromConfig() async {
    await SystemTheme.accentColor.load();
    SystemTheme.fallbackColor = _accentColor;
    if (ConfigProvider.instance.get(Settings.followSystemColor)) {
      _accentColor = SystemTheme.accentColor.accent;
    } else {
      _accentColor = Color(ConfigProvider.instance.get(Settings.accentColor));
    }

    _themeMode = modeFor(ConfigProvider.instance.get(Settings.theme));
    notifyListeners();
  }

  ThemeMode get currentThemeMode {
    return _themeMode;
  }
}
