// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/import_fixtures.dart';

ImportFormatOption fakeOption(ImportFormat format, List<ImportFormat> calls) {
  return ImportFormatOption(
    format,
    (localizations) => format.name,
    (source) async {
      calls.add(format);
      return const ImportBundle();
    },
  );
}

void main() {
  group('ImportRegistry', () {
    test('parses with the parser registered for a format', () async {
      final calls = <ImportFormat>[];
      final registry = ImportRegistry([
        fakeOption(ImportFormat.daylio, calls),
        fakeOption(ImportFormat.pixels, calls),
      ]);

      for (final format in [ImportFormat.pixels, ImportFormat.daylio]) {
        await registry.optionFor(format).parse(const ImportSource('', ''));
      }

      expect(calls, equals([ImportFormat.pixels, ImportFormat.daylio]));
    });

    test('offers every registered format', () {
      final registry = ImportRegistry([
        fakeOption(ImportFormat.oneShot, []),
      ]);

      expect(registry.options.map((option) => option.format),
          equals([ImportFormat.oneShot]));
    });

    test('covers every import format exactly once', () {
      final registered =
          ImportRegistry.instance.options.map((option) => option.format);

      expect(registered.toSet(), equals(ImportFormat.values.toSet()));
      expect(registered, hasLength(ImportFormat.values.length));
    });

    test('has a fixture for every format', () {
      for (final option in ImportRegistry.instance.options) {
        expect(fixtureInputDirectory(option.format).existsSync(), isTrue,
            reason: '${option.format.name} has no fixture');
      }
    });

    test('names every format distinctly', () async {
      final localizations =
          await AppLocalizations.delegate.load(const Locale('en'));

      final names = ImportRegistry.instance.options
          .map((option) => option.name(localizations))
          .toList();

      expect(names.where((name) => name.isEmpty), isEmpty);
      expect(names.toSet(), hasLength(names.length));
    });
  });
}
