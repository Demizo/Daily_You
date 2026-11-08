// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

import '../../support/import_fixture_staging.dart';
import '../../support/import_fixtures.dart';
import '../../support/import_run_harness.dart';

void main() {
  final harness = ImportRunHarness();
  useImportRunHarness(harness);

  final registry = ImportRegistry.instance;

  testWidgets('imports a single file and removes the staged copy',
      (tester) async {
    final context = await harness.pumpContext(tester);
    final fixtureFile = fixtureInputDirectory(ImportFormat.dailyYouJson)
        .listSync()
        .whereType<File>()
        .single;

    await tester.runAsync(() async {
      final outcome = await harness.run(context,
          registry.optionFor(ImportFormat.dailyYouJson), fixtureFile.path);

      expect(outcome.succeeded, isTrue);
      expect(EntriesProvider.instance.entries, hasLength(7));
      expect(harness.leftoverTemporaryFiles, isEmpty);
    });
  });

  testWidgets('extracts an archive, imports it and removes the staged files',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final archive = await zipDirectoryContents(
          fixtureInputDirectory(ImportFormat.daybook));

      final outcome = await harness.run(
          context, registry.optionFor(ImportFormat.daybook), archive);

      expect(outcome.succeeded, isTrue);
      expect(EntriesProvider.instance.entries, hasLength(6));
      expect(await harness.imageFiles.list(), hasLength(2));
      expect(harness.leftoverTemporaryFiles, isEmpty);
    });
  });

  testWidgets('removes the extracted files when the archive has no entries',
      (tester) async {
    final context = await harness.pumpContext(tester);
    final emptyFolder = Directory.systemTemp.createTempSync('import_empty');
    addTearDown(() => emptyFolder.deleteSync(recursive: true));
    File(join(emptyFolder.path, 'unrelated.txt')).writeAsStringSync('x');

    await tester.runAsync(() async {
      final archive = await zipDirectoryContents(emptyFolder);

      final outcome = await harness.run(
          context, registry.optionFor(ImportFormat.daybook), archive);

      expect(outcome.failed, isTrue);
      expect(EntriesProvider.instance.entries, isEmpty);
      expect(harness.leftoverTemporaryFiles, isEmpty);
    });
  });

  testWidgets('imports a SQLite database and removes the staged copy',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final source = await stageDiariumFixture();

      final outcome = await harness.run(
          context,
          registry.optionFor(ImportFormat.diarium),
          join(source.directoryPath, source.fileName));

      expect(outcome.succeeded, isTrue);
      expect(EntriesProvider.instance.entries, hasLength(4));
      expect(await harness.imageFiles.list(), hasLength(5));
      expect(TagsProvider.instance.tags, hasLength(4));
      expect(TagsProvider.instance.categories.map((category) => category.name),
          equals(['People']));
      expect(harness.leftoverTemporaryFiles, isEmpty);
    });
  });

  testWidgets('reports failure and removes the staged copy when parsing fails',
      (tester) async {
    final context = await harness.pumpContext(tester);
    final notJson = File(join(harness.temporaryDirectory.path, 'notes.json'))
      ..writeAsStringSync('not json');

    await tester.runAsync(() async {
      final outcome = await harness.run(
          context, registry.optionFor(ImportFormat.dailyYouJson), notJson.path);

      expect(outcome.failed, isTrue);
      expect(outcome.error, isNotNull);
      expect(EntriesProvider.instance.entries, isEmpty);
      expect(harness.leftoverTemporaryFiles.map((entity) => entity.path),
          equals([notJson.path]));
    });
  });

  testWidgets('is cancelled when no file is picked', (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final outcome = await registry.optionFor(ImportFormat.dailyYouJson).run(
          context, (_) {},
          pickFile: ({allowedExtensions, mimeTypes}) async => null);

      expect(outcome.status.name, 'cancelled');
      expect(harness.leftoverTemporaryFiles, isEmpty);
    });
  });

  testWidgets('reports failure when the picker throws', (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final outcome = await registry.optionFor(ImportFormat.dailyYouJson).run(
          context, (_) {},
          pickFile: ({allowedExtensions, mimeTypes}) =>
              throw Exception('picker failed'));

      expect(outcome.failed, isTrue);
    });
  });
}
