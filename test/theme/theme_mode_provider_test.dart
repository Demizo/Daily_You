// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  test('maps every stored theme to a theme mode', () {
    expect(ThemeModeProvider.modeFor('system'), ThemeMode.system);
    expect(ThemeModeProvider.modeFor('light'), ThemeMode.light);
    expect(ThemeModeProvider.modeFor('dark'), ThemeMode.dark);
    expect(ThemeModeProvider.modeFor('amoled'), ThemeMode.dark);
  });

  test('setTheme switches the mode and stores the theme', () async {
    final provider = ThemeModeProvider();

    await provider.setTheme('dark');

    expect(provider.themeMode, ThemeMode.dark);
    expect(ConfigProvider.instance.get(Settings.theme), 'dark');
  });
}
