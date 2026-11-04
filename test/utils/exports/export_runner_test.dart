// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/exports/export_registry.dart';
import 'package:daily_you/utils/exports/export_runner.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' show basename, join;

import '../../support/export_harness.dart';

void main() {
  final harness = ExportHarness();
  useExportHarness(harness);

  setUpAll(() => initializeDateFormatting('en'));

  final allTypes = {...AttachmentType.values};

  Future<OperationOutcome> run(
    BuildContext context,
    ExportFormatOption option, {
    Set<AttachmentType>? includedTypes,
  }) =>
      runExport(context, (_) {},
          option: option,
          pickAttachmentTypes: (_) async => includedTypes ?? allTypes,
          pickDirectory: () async =>
              PickedDirectory(harness.destinationDirectory.path));

  ExportFormatOption fakeOption(Future<Map<String, String>> Function() write) =>
      ExportFormatOption(
        ExportFormat.markdown,
        (_) => 'fake',
        (snapshot, store) async {
          await store.write('document.txt', utf8.encode('document'));
          return write();
        },
        documentName: 'document.txt',
        documentMimeType: 'text/plain',
      );

  Future<Directory> extractOnlyExport() async {
    final exported = harness.destinationDirectory.listSync().single as File;
    final target = Directory(join(harness.workDirectory.path, 'extracted'));
    await ZipUtils.extract(exported.path, target.path);
    return target;
  }

  testWidgets('zips Markdown notes even when no attachment is included',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      await harness.addEntry(DateTime(2026, 3, 4), text: 'a good day');

      final outcome = await run(
          context, ExportRegistry.instance.optionFor(ExportFormat.markdown),
          includedTypes: {});

      final exported = harness.destinationDirectory.listSync().single;
      expect(outcome.succeeded, isTrue);
      expect(basename(exported.path),
          matches(RegExp(r'^daily_you_markdown_export_.+\.zip$')));
      final extracted = await extractOnlyExport();
      expect(
          File(join(extracted.path, 'logs', 'log_2026-03-04.md'))
              .readAsStringSync(),
          contains('a good day'));
    });
  });

  testWidgets('zips the notes with the attachments where the links point',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      await harness.addEntry(DateTime(2026, 3, 4), attachments: [
        const SeededAttachment(AttachmentType.image, 'a.jpg', [1, 2, 3]),
        const SeededAttachment(AttachmentType.video, 'a.mp4', [4, 5], rank: 1),
      ]);

      final outcome = await run(
          context, ExportRegistry.instance.optionFor(ExportFormat.markdown));

      final extracted = await extractOnlyExport();
      expect(outcome.succeeded, isTrue);
      expect(
          File(join(extracted.path, 'logs', 'Images', 'image_2026-03-04_0.jpg'))
              .readAsBytesSync(),
          [1, 2, 3]);
      expect(
          File(join(extracted.path, 'logs', 'Video', 'video_2026-03-04_1.mp4'))
              .readAsBytesSync(),
          [4, 5]);
      expect(
          File(join(extracted.path, 'logs', 'log_2026-03-04.md'))
              .readAsStringSync(),
          startsWith('[video_2026-03-04_1.mp4](Video/video_2026-03-04_1.mp4)\n'
              '![](Images/image_2026-03-04_0.jpg)\n'));
    });
  });

  testWidgets('leaves out attachment types that were not included',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      await harness.addEntry(DateTime(2026, 3, 4), attachments: [
        const SeededAttachment(AttachmentType.image, 'a.jpg', [1]),
        const SeededAttachment(AttachmentType.video, 'a.mp4', [2], rank: 1),
      ]);

      await run(
          context, ExportRegistry.instance.optionFor(ExportFormat.markdown),
          includedTypes: {AttachmentType.image});

      final extracted = await extractOnlyExport();
      expect(Directory(join(extracted.path, 'logs', 'Images')).existsSync(),
          isTrue);
      expect(Directory(join(extracted.path, 'logs', 'Video')).existsSync(),
          isFalse);
    });
  });

  testWidgets('copies a lone document as a plain file', (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final outcome = await run(context, fakeOption(() async => {}));

      final exported = harness.destinationDirectory.listSync().single as File;
      expect(outcome.succeeded, isTrue);
      expect(basename(exported.path),
          matches(RegExp(r'^daily_you_markdown_export_.+\.txt$')));
      expect(exported.readAsStringSync(), 'document');
    });
  });

  testWidgets('zips the document at the root with the attachments',
      (tester) async {
    final context = await harness.pumpContext(tester);
    final source = File(join(harness.workDirectory.path, 'source'))
      ..writeAsBytesSync([7, 7]);

    await tester.runAsync(() async {
      final outcome = await run(
          context, fakeOption(() async => {'Images/image_x.jpg': source.path}));

      final extracted = await extractOnlyExport();
      expect(outcome.succeeded, isTrue);
      expect(File(join(extracted.path, 'document.txt')).readAsStringSync(),
          'document');
      expect(
          File(join(extracted.path, 'Images', 'image_x.jpg')).readAsBytesSync(),
          [7, 7]);
    });
  });

  testWidgets('removes its temporary files after a success', (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      await run(
          context, ExportRegistry.instance.optionFor(ExportFormat.markdown));

      expect(harness.temporaryDirectory.listSync(), isEmpty);
    });
  });

  testWidgets('reports the real error when writing fails before any zip exists',
      (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final outcome = await run(
          context, fakeOption(() async => throw StateError('disk is full')));

      expect(outcome.failed, isTrue);
      expect(outcome.error, isA<StateError>());
      expect(harness.destinationDirectory.listSync(), isEmpty);
      expect(harness.temporaryDirectory.listSync(), isEmpty);
    });
  });

  testWidgets('reports a failing folder picker', (tester) async {
    final context = await harness.pumpContext(tester);

    await tester.runAsync(() async {
      final outcome = await runExport(context, (_) {},
          option: ExportRegistry.instance.optionFor(ExportFormat.markdown),
          pickAttachmentTypes: (_) async => allTypes,
          pickDirectory: () => throw Exception('picker failed'));

      expect(outcome.failed, isTrue);
      expect(harness.temporaryDirectory.listSync(), isEmpty);
    });
  });

  testWidgets('is cancelled when no attachment choice or folder is given',
      (tester) async {
    final context = await harness.pumpContext(tester);
    final option = ExportRegistry.instance.optionFor(ExportFormat.markdown);

    await tester.runAsync(() async {
      final noChoice = await runExport(context, (_) {},
          option: option, pickAttachmentTypes: (_) async => null);
      final noFolder = await runExport(context, (_) {},
          option: option,
          pickAttachmentTypes: (_) async => allTypes,
          pickDirectory: () async => null);

      expect(noChoice.status, OperationStatus.cancelled);
      expect(noFolder.status, OperationStatus.cancelled);
      expect(harness.temporaryDirectory.listSync(), isEmpty);
    });
  });
}
