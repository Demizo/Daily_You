// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'config_provider_harness.dart';

class ImportRunHarness {
  late Directory temporaryDirectory;
  late Database _database;
  late InMemoryFileStore imageFiles;

  Future<void> setUp() async {
    databaseFactory = databaseFactoryFfi;
    _database = await databaseFactory.openDatabase(inMemoryDatabasePath);
    AppDatabase.instance.database = _database;
    await AppDatabase.instance.createSchema(_database);

    imageFiles = InMemoryFileStore();
    AttachmentStorage.instance.overrideStores(imageFiles, InMemoryFileStore());
    await EntriesProvider.instance.load();

    temporaryDirectory = await Directory.systemTemp.createTemp('import_run');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => switch (call.method) {
                  'getTemporaryDirectory' => temporaryDirectory.path,
                  _ => null,
                });
  }

  Future<void> tearDown() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    AttachmentStorage.instance.clearStoreOverrides();
    AppDatabase.instance.database = null;
    await _database.close();
    await temporaryDirectory.delete(recursive: true);
  }

  List<FileSystemEntity> get leftoverTemporaryFiles =>
      temporaryDirectory.listSync();

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

  Future<OperationOutcome> run(
    BuildContext context,
    ImportFormatOption option,
    String pickedPath,
  ) =>
      option.run(context, (_) {},
          pickFile: ({allowedExtensions, mimeTypes}) async =>
              PickedFile(pickedPath));
}

void useImportRunHarness(ImportRunHarness harness) {
  useTemporaryConfig();
  setUpAll(sqfliteFfiInit);
  setUp(harness.setUp);
  tearDown(harness.tearDown);
}

Future<String> zipDirectoryContents(Directory directory) async {
  final outputDirectory = await Directory.systemTemp.createTemp('import_zip');
  addTearDown(() => outputDirectory.delete(recursive: true));
  final archive = join(outputDirectory.path, 'fixture.zip');
  final children = directory.listSync();
  await ZipUtils.compress(
    archive,
    [for (final child in children.whereType<File>()) child.path],
    [for (final child in children.whereType<Directory>()) child.path],
  );
  return archive;
}
