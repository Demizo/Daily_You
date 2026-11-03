// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  late Directory supportDirectory;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    supportDirectory =
        await Directory.systemTemp.createTemp('app_database_fresh_install');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => switch (call.method) {
                  'getApplicationSupportDirectory' => supportDirectory.path,
                  _ => null,
                });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    await AppDatabase.instance.database?.close();
    AppDatabase.instance.database = null;
    await supportDirectory.delete(recursive: true);
  });

  test('a fresh install starts with the emoji preset on every level', () async {
    await AppDatabase.instance.init();

    final levels = MoodScaleProvider.instance.levels;
    expect(levels.map((level) => level.mood), Mood.levels);
    expect(levels.map((level) => level.toJson()),
        MoodScalePreset.emoji.levels.map((level) => level.toJson()));
  });
}
