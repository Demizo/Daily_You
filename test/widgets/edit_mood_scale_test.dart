// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/widgets/edit_mood_scale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  late List<MoodScaleLevel>? result;
  late bool finished;

  final initial = [
    for (final level in MoodScalePreset.emoji.levels)
      level.copyWith(label: 'Mood ${level.mood}'),
  ];

  Future<void> openEditor(WidgetTester tester) async {
    result = null;
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
            result = await showDialog<List<MoodScaleLevel>>(
              context: context,
              builder: (_) => EditMoodScale(initial: initial),
            );
            finished = true;
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('scrolls on a short screen', (tester) async {
    tester.view.physicalSize = const Size(400, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await openEditor(tester);

    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -400));
    await tester.pump();
    expect(find.text('OK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a preset replaces icons and colors but keeps labels',
      (tester) async {
    await openEditor(tester);

    await tester.tap(find.byType(FittedBox).at(2));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result!.map((level) => level.icon),
        MoodScalePreset.colors.levels.map((level) => level.icon));
    expect(result!.map((level) => level.color),
        MoodScalePreset.colors.levels.map((level) => level.color));
    expect(result!.map((level) => level.label),
        initial.map((level) => level.label));
  });

  testWidgets('cancel discards a preset that was tried', (tester) async {
    await openEditor(tester);

    await tester.tap(find.byType(FittedBox).at(1));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(result, isNull);
  });

  testWidgets('a cleared label is saved as no label', (tester) async {
    await openEditor(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Mood 1'), '');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(result!.first.label, isNull);
    expect(result!.last.label, 'Mood 5');
  });
}
