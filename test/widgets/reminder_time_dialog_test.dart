// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/reminder_time_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/config_provider_harness.dart';

const _ringRadius = 260 / 2 - 28;
const _startHandle = ValueKey('time-range-start');
const _endHandle = ValueKey('time-range-end');

TimeRangeSelection _range(int startHour, int endHour,
        {int startMinute = 0, int endMinute = 0}) =>
    (
      start: TimeOfDay(hour: startHour, minute: startMinute),
      end: TimeOfDay(hour: endHour, minute: endMinute),
    );

void main() {
  useTemporaryConfig();

  late ReminderTimeSelection? picked;
  late bool finished;

  Future<void> openPicker(
    WidgetTester tester, {
    bool fixed = false,
  }) async {
    picked = null;
    finished = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...appLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showReminderTimePicker(context, initial: (
              fixed: fixed,
              time: const TimeOfDay(hour: 8, minute: 30),
              range: _range(9, 21),
            ));
            finished = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Offset ringPoint(WidgetTester tester, double hours,
      {double handleHours = 9}) {
    final startAngle = handleHours / 24 * 2 * math.pi - math.pi / 2;
    final center = tester.getCenter(find.byKey(_startHandle)) -
        Offset(math.cos(startAngle), math.sin(startAngle)) * _ringRadius;
    final angle = hours / 24 * 2 * math.pi - math.pi / 2;
    return center + Offset(math.cos(angle), math.sin(angle)) * _ringRadius;
  }

  Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(0, 1));
    await gesture.moveTo(to);
    await gesture.up();
    await tester.pump();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  }

  testWidgets('returns the initial range when confirmed untouched',
      (tester) async {
    await openPicker(tester);
    await confirm(tester);

    expect(picked?.range, _range(9, 21));
  });

  testWidgets('returns nothing when cancelled', (tester) async {
    await openPicker(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(picked, isNull);
  });

  testWidgets('dragging the start handle moves only the start', (tester) async {
    await openPicker(tester);
    await drag(tester, tester.getCenter(find.byKey(_startHandle)),
        ringPoint(tester, 3));
    await confirm(tester);

    expect(picked?.range, _range(3, 21));
  });

  testWidgets('snaps the end handle to ten minutes', (tester) async {
    await openPicker(tester);
    await drag(tester, tester.getCenter(find.byKey(_endHandle)),
        ringPoint(tester, 12 + 7 / 60));
    await confirm(tester);

    expect(picked?.range, _range(9, 12, endMinute: 10));
  });

  testWidgets('dragging the range keeps its length and wraps past midnight',
      (tester) async {
    await openPicker(tester);
    await drag(tester, ringPoint(tester, 15), ringPoint(tester, 18));
    await confirm(tester);

    expect(picked?.range, _range(12, 0));
  });

  testWidgets('ignores drags that start away from the range', (tester) async {
    await openPicker(tester);
    await drag(tester, ringPoint(tester, 3), ringPoint(tester, 5));
    await confirm(tester);

    expect(picked?.range, _range(9, 21));
  });

  testWidgets('defaults to a range and keeps the fixed time', (tester) async {
    await openPicker(tester);
    await confirm(tester);

    expect(picked?.fixed, isFalse);
    expect(picked?.time, const TimeOfDay(hour: 8, minute: 30));
  });

  testWidgets('the fixed switch swaps the range for a single time',
      (tester) async {
    await openPicker(tester);
    expect(find.byKey(_endHandle), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.byKey(_endHandle), findsNothing);

    await drag(tester, tester.getCenter(find.byKey(_startHandle)),
        ringPoint(tester, 18, handleHours: 8.5));
    await confirm(tester);

    expect(picked?.fixed, isTrue);
    expect(picked?.time, const TimeOfDay(hour: 18, minute: 0));
    expect(picked?.range, _range(9, 21));
  });

  Future<void> enterExactTime(
      WidgetTester tester, String hour, String minute) async {
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, hour);
    await tester.enterText(find.byType(TextField).last, minute);
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
  }

  testWidgets('time buttons are primary text on a rounded card',
      (tester) async {
    await openPicker(tester);
    final button = find.byKey(const ValueKey('time-range-start-button'));
    final colorScheme = Theme.of(tester.element(button)).colorScheme;

    final text = tester.element(
      find.descendant(of: button, matching: find.byType(Text)),
    );
    expect(DefaultTextStyle.of(text).style.color, colorScheme.primary);

    final material = tester.widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    );
    expect(material.color, colorScheme.surfaceContainerHighest);
    expect(material.shape, isA<RoundedRectangleBorder>());
  });

  testWidgets('tapping the start time sets an exact start', (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('time-range-start-button')));
    await tester.pumpAndSettle();
    await enterExactTime(tester, '7', '45');
    await confirm(tester);

    expect(picked?.range, _range(7, 21, startMinute: 45));
  });

  testWidgets('tapping the end time sets an exact end', (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('time-range-end-button')));
    await tester.pumpAndSettle();
    await enterExactTime(tester, '10', '5');
    await confirm(tester);

    expect(picked?.range, _range(9, 22, endMinute: 5));
  });

  testWidgets('tapping the fixed time sets an exact time', (tester) async {
    await openPicker(tester, fixed: true);
    await tester.tap(find.byKey(const ValueKey('time-range-start-button')));
    await tester.pumpAndSettle();
    await enterExactTime(tester, '6', '17');
    await confirm(tester);

    expect(picked?.time, const TimeOfDay(hour: 6, minute: 17));
    expect(picked?.range, _range(9, 21));
  });

  testWidgets('cancelling the exact time keeps the current one',
      (tester) async {
    await openPicker(tester);
    await tester.tap(find.byKey(const ValueKey('time-range-start-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(picked?.range, _range(9, 21));
  });

  testWidgets('opens on the fixed time when fixed is set', (tester) async {
    await openPicker(tester, fixed: true);

    expect(find.byKey(_endHandle), findsNothing);
    await confirm(tester);

    expect(picked?.fixed, isTrue);
  });
}
