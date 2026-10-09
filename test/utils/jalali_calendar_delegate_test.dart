// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/jalali_calendar_delegate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  const delegate = JalaliCalendarDelegate();

  group('JalaliCalendarDelegate', () {
    test('reads the Jalali date and orders by the Gregorian date', () {
      final date = JalaliDate.fromJalali(Jalali(1404, 1, 1));

      expect([date.year, date.month, date.day], [1404, 1, 1]);
      expect(date.gregorian, Jalali(1404, 1, 1).toDateTime());
      expect(date.isBefore(date.add(const Duration(days: 1))), isTrue);
      expect(date.isAfter(Jalali(1403, 12, 29).toDateTime()), isTrue);
    });

    test('moves between months across a year boundary', () {
      final lastMonth = delegate.getMonth(1403, 12);
      final nextYear = delegate.addMonthsToMonthDate(lastMonth, 1);
      final previousYear = delegate.addMonthsToMonthDate(nextYear, -2);

      expect([nextYear.year, nextYear.month], [1404, 1]);
      expect([previousYear.year, previousYear.month], [1403, 11]);
      expect(delegate.monthDelta(lastMonth, nextYear), 1);
      expect(delegate.monthDelta(previousYear, nextYear), 2);
    });

    test('uses the Jalali month lengths', () {
      expect(delegate.getDaysInMonth(1404, 1), 31);
      expect(delegate.getDaysInMonth(1404, 7), 30);
      expect(delegate.getDaysInMonth(1404, 12), 29);
      expect(delegate.getDaysInMonth(1403, 12), 30);
    });

    test('adds days across a month boundary', () {
      final date = delegate.getDay(1404, 1, 31);
      final next = delegate.addDaysToDate(date, 1);

      expect([next.year, next.month, next.day], [1404, 2, 1]);
    });

    test('round trips compact dates and rejects invalid ones', () {
      final localizations = DefaultMaterialLocalizations();
      final date = delegate.getDay(1404, 7, 9);

      expect(delegate.formatCompactDate(date, localizations), '1404/07/09');
      expect(delegate.parseCompactDate('1404/07/09', localizations), date);
      expect(delegate.parseCompactDate('1404/13/01', localizations), isNull);
      expect(delegate.parseCompactDate('1404/12/30', localizations), isNull);
      expect(delegate.parseCompactDate('soon', localizations), isNull);
    });
  });

  group('TimeManager.pickDate', () {
    Future<DateTime?> pick(WidgetTester tester,
        {required Future<void> Function() interact}) async {
      await ConfigProvider.instance.set(Settings.calendarSystem, 'jalali');
      DateTime? picked;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await TimeManager.pickDate(
              context,
              initialDate: Jalali(1404, 7, 9).toDateTime(),
              firstDate: Jalali(1400, 1, 1).toDateTime(),
              lastDate: Jalali(1410, 1, 1).toDateTime(),
              selectableDayPredicate: (date) => date.weekday != DateTime.friday,
            ),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await interact();
      await tester.tap(find.descendant(
          of: find.byType(Dialog), matching: find.byType(TextButton).last));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('returns the tapped Jalali day as a Gregorian date',
        (tester) async {
      final picked =
          await pick(tester, interact: () => tester.tap(find.text('۱۵')));

      expect(picked, Jalali(1404, 7, 15).toDateTime());
      expect(picked, isNot(isA<JalaliDate>()));
    });

    testWidgets('does not select days the predicate rejects', (tester) async {
      final friday = Jalali.fromDateTime(DateTime(2025, 10, 3));
      final picked = await pick(tester,
          interact: () => tester.tap(
              find.text(NumberFormat.decimalPattern('fa').format(friday.day))));

      expect(picked, Jalali(1404, 7, 9).toDateTime());
    });
  });
}
