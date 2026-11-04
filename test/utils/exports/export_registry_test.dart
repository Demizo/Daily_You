// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/exports/export_registry.dart';
import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/export_snapshots.dart';

ExportFormatOption fakeOption(ExportFormat format, List<ExportFormat> calls) {
  return ExportFormatOption(format, (localizations) => format.name,
      (snapshot, store) async {
    calls.add(format);
    return {};
  });
}

void main() {
  group('ExportRegistry', () {
    test('writes with the writer registered for a format', () async {
      final calls = <ExportFormat>[];
      final registry = ExportRegistry([
        for (final format in ExportFormat.values) fakeOption(format, calls),
      ]);

      for (final format in ExportFormat.values.reversed) {
        await registry
            .optionFor(format)
            .write(snapshotOf([]), InMemoryFileStore());
      }

      expect(calls, equals(ExportFormat.values.reversed.toList()));
    });

    test('covers every export format exactly once', () {
      final registered =
          ExportRegistry.instance.options.map((option) => option.format);

      expect(registered.toSet(), equals(ExportFormat.values.toSet()));
      expect(registered, hasLength(ExportFormat.values.length));
    });

    test('names every format distinctly', () async {
      final localizations =
          await AppLocalizations.delegate.load(const Locale('en'));

      final names = ExportRegistry.instance.options
          .map((option) => option.name(localizations))
          .toList();

      expect(names.where((name) => name.isEmpty), isEmpty);
      expect(names.toSet(), hasLength(names.length));
    });
  });
}
