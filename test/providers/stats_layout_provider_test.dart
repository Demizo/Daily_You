// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/stats_layout_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  late Database database;
  late StatsLayoutProvider provider;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = database;
    await AppDatabase.instance.createSchema(database);
    await TagsProvider.instance.load();
    provider = StatsLayoutProvider(TagsProvider.instance);
  });

  tearDown(() async {
    provider.dispose();
    AppDatabase.instance.database = null;
    await database.close();
  });

  Future<List<int>> addTags(int count) async {
    final now = DateTime(2026, 1, 1);
    for (var index = 0; index < count; index++) {
      await TagsProvider.instance.add(Tag(
        name: 'tag$index',
        tagType: index.isEven ? TagType.label : TagType.tracker,
        timeCreate: now,
        timeModified: now,
      ));
    }
    return [for (final tag in TagsProvider.instance.tags) tag.id!];
  }

  Future<void> relaunch() async {
    EasyDebounce.fire('save-config');
    final configFile = File(ConfigProvider.instance.configFilePath);
    while (!configFile.existsSync()) {
      await Future.delayed(Duration.zero);
    }
    await ConfigProvider.instance.readConfig();
    provider.dispose();
    provider = StatsLayoutProvider(TagsProvider.instance);
  }

  group('first load', () {
    test('pins the first four tags when nothing is saved', () async {
      final tagIds = await addTags(6);

      await provider.load();

      expect(provider.pinnedTagIds, tagIds.take(4));
      expect(ConfigProvider.instance.get(Settings.statsPinnedTagIds),
          tagIds.take(4));
    });

    test('pins every tag when there are fewer than four', () async {
      final tagIds = await addTags(2);

      await provider.load();

      expect(provider.pinnedTagIds, tagIds);
    });

    test('stays unset without tags so it seeds once tags exist', () async {
      await provider.load();
      expect(provider.pinnedTagIds, isEmpty);
      expect(ConfigProvider.instance.get(Settings.statsPinnedTagIds), isNull);

      final tagIds = await addTags(1);
      await provider.load();

      expect(provider.pinnedTagIds, tagIds);
    });

    test('keeps an empty saved list empty', () async {
      await addTags(5);
      await provider.replace([]);

      await provider.load();

      expect(provider.pinnedTagIds, isEmpty);
    });

    test('keeps the saved order', () async {
      final tagIds = await addTags(5);
      await provider.replace([tagIds[3], tagIds[0]]);

      await provider.load();

      expect(provider.pinnedTagIds, [tagIds[3], tagIds[0]]);
    });
  });

  group('editing', () {
    late List<int> tagIds;

    setUp(() async {
      tagIds = await addTags(5);
      await provider.load();
    });

    test('replaces the whole list and notifies once', () async {
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.replace([tagIds[4], tagIds[2]]);

      expect(provider.pinnedTagIds, [tagIds[4], tagIds[2]]);
      expect(notifications, 1);
    });

    test('can not be edited through the exposed list', () {
      expect(() => provider.pinnedTagIds.add(1), throwsUnsupportedError);
    });
  });

  group('persistence', () {
    test('brings the pinned tags back after a relaunch', () async {
      final tagIds = await addTags(5);
      await provider.load();
      await provider.replace([tagIds[4], tagIds[1]]);

      await relaunch();
      await provider.load();

      expect(provider.pinnedTagIds, [tagIds[4], tagIds[1]]);
    });

    test('brings back an emptied list after a relaunch', () async {
      await addTags(5);
      await provider.load();
      await provider.replace([]);

      await relaunch();
      await provider.load();

      expect(provider.pinnedTagIds, isEmpty);
    });
  });

  group('pruning', () {
    late List<int> tagIds;
    late int notifications;

    setUp(() async {
      tagIds = await addTags(5);
      await provider.load();
      notifications = 0;
      provider.addListener(() => notifications++);
    });

    test('drops a deleted tag at once and saves the rest', () async {
      final deleted =
          TagsProvider.instance.tags.firstWhere((tag) => tag.id == tagIds[1]);

      await TagsProvider.instance.remove(deleted);

      expect(provider.pinnedTagIds, [tagIds[0], tagIds[2], tagIds[3]]);
      expect(notifications, 1);
      expect(ConfigProvider.instance.get(Settings.statsPinnedTagIds),
          [tagIds[0], tagIds[2], tagIds[3]]);
    });

    test('drops tags missing after the database is replaced', () async {
      await TagDao.remove(tagIds[0]);
      await TagDao.remove(tagIds[3]);

      await TagsProvider.instance.load();

      expect(provider.pinnedTagIds, [tagIds[1], tagIds[2]]);
      expect(ConfigProvider.instance.get(Settings.statsPinnedTagIds),
          [tagIds[1], tagIds[2]]);
    });

    test('drops saved tags that no longer exist when loading', () async {
      await provider.replace([tagIds[0], 999, tagIds[2]]);

      await provider.load();

      expect(provider.pinnedTagIds, [tagIds[0], tagIds[2]]);
    });

    test('stays quiet when no pinned tag went away', () async {
      await TagsProvider.instance.load();
      await TagsProvider.instance.remove(
        TagsProvider.instance.tags.firstWhere((tag) => tag.id == tagIds[4]),
      );

      expect(provider.pinnedTagIds, tagIds.take(4));
      expect(notifications, 0);
    });
  });
}
