// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/date_range_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  DateTimeRange? picked;

  Future<void> openPicker(
    WidgetTester tester, {
    required DateTime firstDate,
    required DateTime lastDate,
    DateTimeRange? initialRange,
  }) async {
    picked = null;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...appLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked = await showDateRangeDialog(
            context,
            initialRange: initialRange,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder day(String label) => find.descendant(
        of: find.byType(DateRangeDialog),
        matching: find.text(label),
      );

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('selects a range from two taps', (tester) async {
    await openPicker(
      tester,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 3, 15),
    );

    await tester.tap(day('5'));
    await tester.tap(day('12'));
    await tester.pump();
    await confirm(tester);

    expect(
        picked,
        DateTimeRange(
          start: DateTime(2026, 3, 5),
          end: DateTime(2026, 3, 12),
        ));
  });

  testWidgets('a second tap on an earlier day makes it the start',
      (tester) async {
    await openPicker(
      tester,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 3, 15),
    );

    await tester.tap(day('12'));
    await tester.tap(day('5'));
    await tester.pump();
    await confirm(tester);

    expect(
        picked,
        DateTimeRange(
          start: DateTime(2026, 3, 5),
          end: DateTime(2026, 3, 12),
        ));
  });

  testWidgets('cannot confirm before a day is chosen', (tester) async {
    await openPicker(
      tester,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 3, 15),
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangeDialog), findsOneWidget);
    expect(picked, isNull);
  });

  testWidgets('days outside the allowed dates cannot be selected',
      (tester) async {
    await openPicker(
      tester,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 3, 15),
    );

    await tester.tap(day('20'));
    await tester.pump();

    expect(find.text('Start Date – End Date'), findsOneWidget);
  });

  testWidgets('the previous month button shows earlier days', (tester) async {
    await openPicker(
      tester,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 3, 15),
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(day('28'));
    await tester.tap(day('20'));
    await tester.pump();
    await confirm(tester);

    expect(
        picked,
        DateTimeRange(
          start: DateTime(2026, 2, 20),
          end: DateTime(2026, 2, 28),
        ));
  });

  testWidgets('shows the month of the initial range', (tester) async {
    await openPicker(
      tester,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 3, 15),
      initialRange: DateTimeRange(
        start: DateTime(2026, 1, 10),
        end: DateTime(2026, 1, 12),
      ),
    );

    expect(find.text('January 2026'), findsOneWidget);
    await confirm(tester);

    expect(
        picked,
        DateTimeRange(
          start: DateTime(2026, 1, 10),
          end: DateTime(2026, 1, 12),
        ));
  });

  testWidgets('selects in the Jalali calendar and returns Gregorian dates',
      (tester) async {
    await ConfigProvider.instance.set(Settings.calendarSystem, 'jalali');
    await openPicker(
      tester,
      firstDate: Jalali(1404, 1, 1).toDateTime(),
      lastDate: Jalali(1404, 3, 31).toDateTime(),
    );

    await tester.tap(day('9'));
    await tester.tap(day('3'));
    await tester.pump();
    await confirm(tester);

    expect(
        picked,
        DateTimeRange(
          start: Jalali(1404, 3, 3).toDateTime(),
          end: Jalali(1404, 3, 9).toDateTime(),
        ));
  });
}
