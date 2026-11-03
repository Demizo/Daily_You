// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/models/tag_icon_type.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
  });

  tearDown(() async {
    AppDatabase.instance.database = null;
    await database.close();
  });

  test('saves every level and reloads them in order', () async {
    final provider = MoodScaleProvider.instance;

    await provider.save(MoodScalePreset.emoji.levels.reversed.toList());
    await provider.load();

    expect(provider.levels.map((level) => level.mood), Mood.levels);
    expect(provider.levels.map((level) => level.icon),
        MoodScalePreset.emoji.levels.map((level) => level.icon));
  });

  test('saving again replaces the look of a level', () async {
    final provider = MoodScaleProvider.instance;
    await provider.save(MoodScalePreset.emoji.levels);
    final worst = Mood.levels.first;

    await provider.save([
      MoodScaleLevel(
        mood: worst,
        label: 'Awful',
        icon: 'X',
        iconType: TagIconType.character,
        color: 0xff112233,
      ),
      ...MoodScalePreset.emoji.levels.skip(1),
    ]);

    expect(provider.levels, hasLength(Mood.count));
    final level = provider.levelOf(worst)!;
    expect(level.label, 'Awful');
    expect(level.icon, 'X');
    expect(level.color, 0xff112233);
  });

  test('has no scale level for a missing mood', () async {
    await MoodScaleProvider.instance.save(MoodScalePreset.emoji.levels);

    expect(MoodScaleProvider.instance.levelOf(null), isNull);
  });
}
