import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

ImportFormatOption fakeOption(ImportFormat format, List<ImportFormat> calls) {
  return ImportFormatOption(
    format,
    (localizations) => format.name,
    (context, updateStatus) async {
      calls.add(format);
      return const OperationOutcome.succeeded();
    },
  );
}

void main() {
  group('ImportRegistry', () {
    test('runs the importer registered for a format', () async {
      final calls = <ImportFormat>[];
      final registry = ImportRegistry([
        fakeOption(ImportFormat.daylio, calls),
        fakeOption(ImportFormat.pixels, calls),
      ]);

      for (final format in [ImportFormat.pixels, ImportFormat.daylio]) {
        await registry.optionFor(format).run(_NoContext(), (_) {});
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

class _NoContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
