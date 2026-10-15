// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/widgets/edit_mood_scale.dart';
import 'package:daily_you/widgets/mood_scale_glyph.dart';
import 'package:daily_you/widgets/mood_scale_setting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  Future<void> pumpSetting(WidgetTester tester,
      {MoodScalePreset preset = MoodScalePreset.emoji}) async {
    MoodScaleProvider.instance.levels = preset.levels;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...appLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider.value(
          value: MoodScaleProvider.instance,
          child: const MoodScaleSetting(),
        ),
      ),
    ));
  }

  testWidgets('shows a glyph for every level', (tester) async {
    await pumpSetting(tester);

    expect(find.byType(MoodScaleGlyph), findsNWidgets(5));
  });

  testWidgets('tapping a glyph opens the editor', (tester) async {
    await pumpSetting(tester);

    await tester.tap(find.byType(MoodScaleGlyph).first);
    await tester.pumpAndSettle();

    expect(find.byType(EditMoodScale), findsOneWidget);
  });

  List<BoxDecoration> circleDecorations(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(find.byWidgetPredicate((widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle))
      .map((box) => box.decoration as BoxDecoration)
      .toList();

  testWidgets('rings text glyphs in their level color on the surface color',
      (tester) async {
    await pumpSetting(tester);

    final surface = Theme.of(tester.element(find.byType(MoodScaleSetting)))
        .colorScheme
        .surface;
    final levels = MoodScalePreset.emoji.levels;
    final decorations = circleDecorations(tester);

    expect(decorations, hasLength(levels.length));
    for (final (index, decoration) in decorations.indexed) {
      expect(decoration.color, surface);
      expect(
          (decoration.border as Border).top.color, Color(levels[index].color!));
    }
  });

  testWidgets('leaves icon glyphs unringed', (tester) async {
    await pumpSetting(tester, preset: MoodScalePreset.icons);

    for (final decoration in circleDecorations(tester)) {
      expect(decoration.border, isNull);
    }
  });
}
