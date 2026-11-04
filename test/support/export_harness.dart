// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/database/tag_category_dao.dart';
import 'package:daily_you/database/tag_dao.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/models/tag_category.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'config_provider_harness.dart';

class SeededAttachment {
  const SeededAttachment(this.type, this.fileName, this.bytes, {this.rank = 0});

  final AttachmentType type;
  final String fileName;
  final List<int> bytes;
  final int rank;
}

class SeededTag {
  const SeededTag(this.tag, {this.value});

  final Tag tag;
  final String? value;
}

class ExportHarness {
  static const channel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory workDirectory;
  late Database _database;

  Directory get temporaryDirectory =>
      Directory(join(workDirectory.path, 'temporary'));
  Directory get supportDirectory =>
      Directory(join(workDirectory.path, 'support'));
  Directory get destinationDirectory =>
      Directory(join(workDirectory.path, 'destination'));

  Future<void> setUp() async {
    workDirectory = await Directory.systemTemp.createTemp('export_run');
    for (final directory in [
      temporaryDirectory,
      supportDirectory,
      destinationDirectory
    ]) {
      await directory.create();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel,
            (call) async => switch (call.method) {
                  'getTemporaryDirectory' => temporaryDirectory.path,
                  'getApplicationSupportDirectory' => supportDirectory.path,
                  _ => null,
                });
    await openDatabase();
  }

  Future<void> tearDown() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    AttachmentStorage.instance.clearStoreOverrides();
    AppDatabase.instance.database = null;
    await _database.close();
    await workDirectory.delete(recursive: true);
  }

  Future<void> openDatabase() async {
    databaseFactory = databaseFactoryFfi;
    _database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = _database;
    await AppDatabase.instance.createSchema(_database);
    AttachmentStorage.instance.clearStoreOverrides();
    await reloadProviders();
  }

  Future<void> wipe() async {
    await _database.close();
    for (final type in AttachmentType.values) {
      final folder = Directory(join(supportDirectory.path, type.folderName));
      if (await folder.exists()) await folder.delete(recursive: true);
    }
    await openDatabase();
  }

  Future<void> reloadProviders() async {
    await EntriesProvider.instance.load();
    await EntryAttachmentsProvider.instance.load();
    await TagsProvider.instance.load();
    await MoodScaleProvider.instance.load();
  }

  Future<void> saveMoodScale(List<MoodScaleLevel> levels) =>
      MoodScaleProvider.instance.save(levels);

  Future<TagCategory> addCategory(String name,
      {int? color, int sortOrder = 0}) async {
    final category = await TagCategoryDao.add(TagCategory(
        name: name,
        color: color,
        sortOrder: sortOrder,
        timeCreate: DateTime(2026),
        timeModified: DateTime(2026)));
    await TagsProvider.instance.load();
    return category;
  }

  Future<Tag> addTag(String name, TagType tagType,
      {int? categoryId, int? color, int sortOrder = 0}) async {
    final tag = await TagDao.add(Tag(
        name: name,
        tagType: tagType,
        categoryId: categoryId,
        color: color,
        sortOrder: sortOrder,
        timeCreate: DateTime(2026),
        timeModified: DateTime(2026)));
    await TagsProvider.instance.load();
    return tag;
  }

  Future<Entry> addEntry(
    DateTime timeCreate, {
    String text = '',
    int? mood,
    DateTime? timeModified,
    List<SeededTag> tags = const [],
    List<SeededAttachment> attachments = const [],
  }) async {
    final stored = <EntryAttachment>[];
    for (final attachment in attachments) {
      final filePath = await AttachmentStorage.instance.create(
          attachment.fileName,
          Uint8List.fromList(attachment.bytes),
          attachment.type,
          currTime: timeCreate);
      stored.add(EntryAttachment(
          entryId: null,
          type: attachment.type,
          filePath: filePath!,
          rank: attachment.rank,
          timeCreate: timeCreate));
    }

    final saved = await EntryStore.instance.beginDraft().save((_) => EntryDraft(
          entry: Entry(
              text: text,
              mood: mood,
              timeCreate: timeCreate,
              timeModified: timeModified ?? timeCreate),
          tags: [
            for (final seeded in tags)
              EntryTag(
                  entryId: 0,
                  tagId: seeded.tag.id!,
                  value: seeded.value,
                  timeCreate: timeCreate)
          ],
          attachments: stored,
        ));
    await reloadProviders();
    return saved;
  }

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (builderContext) {
        context = builderContext;
        return const SizedBox();
      }),
    ));
    return context;
  }
}

void useExportHarness(ExportHarness harness) {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();
  setUpAll(sqfliteFfiInit);
  setUp(harness.setUp);
  tearDown(harness.tearDown);
}
