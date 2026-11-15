// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_progress_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpBar(
      WidgetTester tester, int count, ValueNotifier<double> position) {
    return tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: OnboardingProgressBar(count: count, position: position),
        ),
      ),
    ));
  }

  List<double> segmentFills(WidgetTester tester) => tester
      .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .map((box) => box.widthFactor!)
      .toList();

  testWidgets('starts with the first segment and check filled', (tester) async {
    await pumpBar(tester, 4, ValueNotifier(0));

    expect(find.byIcon(Icons.check_rounded), findsNWidgets(4));
    expect(segmentFills(tester), [1, 0, 0, 0]);
  });

  testWidgets('fills the next segment while a page is scrolled in',
      (tester) async {
    final position = ValueNotifier<double>(0);
    await pumpBar(tester, 4, position);

    position.value = 1.5;
    await tester.pump();

    expect(segmentFills(tester), [1, 1, 0.5, 0]);
  });

  testWidgets('fills every segment on the last page', (tester) async {
    await pumpBar(tester, 3, ValueNotifier(2));

    expect(segmentFills(tester), [1, 1, 1]);
  });

  testWidgets('fills each check once its segment is full', (tester) async {
    final position = ValueNotifier<double>(0);
    await pumpBar(tester, 3, position);
    Color? checkColor(int index) =>
        tester.widget<Icon>(find.byIcon(Icons.check_rounded).at(index)).color;
    final unfilled = checkColor(2);

    expect(checkColor(0), isNot(unfilled));
    expect(checkColor(1), unfilled);

    position.value = 0.5;
    await tester.pump();
    expect(segmentFills(tester), [1, 0.5, 0]);
    expect(checkColor(1), unfilled);

    position.value = 1;
    await tester.pump();
    expect(checkColor(1), isNot(unfilled));
    expect(checkColor(2), unfilled);
  });

  testWidgets('starts with a segment before the first check', (tester) async {
    await pumpBar(tester, 3, ValueNotifier(0));

    final firstSegment = tester.getRect(find.byType(ClipRRect).first);
    final firstCheck = tester.getRect(find.byIcon(Icons.check_rounded).first);

    expect(firstSegment.left, lessThan(firstCheck.left));
    expect(firstSegment.right, lessThan(firstCheck.left));
  });
}
