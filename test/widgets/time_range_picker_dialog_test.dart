// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/time_range_picker_dialog.dart';
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

  late TimeRangeSelection? picked;
  late bool finished;

  Future<void> openPicker(
    WidgetTester tester, {
    TimeRangeSelection? initialRange,
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
            picked = await showTimeRangePicker(context,
                initialRange: initialRange ?? _range(9, 21));
            finished = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Offset ringPoint(WidgetTester tester, double hours) {
    final startAngle = 9 / 24 * 2 * math.pi - math.pi / 2;
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

    expect(picked, _range(9, 21));
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

    expect(picked, _range(3, 21));
  });

  testWidgets('snaps the end handle to ten minutes', (tester) async {
    await openPicker(tester);
    await drag(tester, tester.getCenter(find.byKey(_endHandle)),
        ringPoint(tester, 12 + 7 / 60));
    await confirm(tester);

    expect(picked, _range(9, 12, endMinute: 10));
  });

  testWidgets('dragging the range keeps its length and wraps past midnight',
      (tester) async {
    await openPicker(tester);
    await drag(tester, ringPoint(tester, 15), ringPoint(tester, 18));
    await confirm(tester);

    expect(picked, _range(12, 0));
  });

  testWidgets('ignores drags that start away from the range', (tester) async {
    await openPicker(tester);
    await drag(tester, ringPoint(tester, 3), ringPoint(tester, 5));
    await confirm(tester);

    expect(picked, _range(9, 21));
  });
}
