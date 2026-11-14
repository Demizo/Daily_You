// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/widgets/attachment_filter_dialog.dart';
import 'package:daily_you/widgets/gallery_filter_pills.dart';
import 'package:daily_you/widgets/mood_filter_dialog.dart';
import 'package:daily_you/widgets/mood_icon.dart';
import 'package:daily_you/widgets/show_logs_button.dart';
import 'package:daily_you/widgets/text_filter_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  final provider = EntriesProvider.instance;

  Future<void> pump(WidgetTester tester, Widget child) async {
    MoodScaleProvider.instance.levels = MoodScalePreset.emoji.levels;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
        ChangeNotifierProvider.value(value: MoodScaleProvider.instance),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...appLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ));
  }

  tearDown(() => provider.filter = const GalleryFilter());

  group('GalleryFilterPills', () {
    testWidgets('shows only the five labels while nothing is active',
        (tester) async {
      await pump(tester, GalleryFilterPills(onClearAll: () {}));

      for (final label in ['Mood', 'Tags', 'Date', 'Keywords', 'Attachments']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Clear All'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('shows values, per pill clear buttons and Clear All',
        (tester) async {
      var clearedAll = false;
      provider.filter = const GalleryFilter(
        tagIds: {1, 2},
        date: LastMonthsSelection(3, isJalali: false),
        textTerms: ['sun'],
      );
      await pump(
          tester, GalleryFilterPills(onClearAll: () => clearedAll = true));

      expect(find.text('2 tags'), findsOneWidget);
      expect(find.text('Last 3 months'), findsOneWidget);
      expect(find.text('1 keyword'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(3));

      await tester.tap(find.text('Clear All'));
      expect(clearedAll, isTrue);
    });

    testWidgets('the clear button of one pill leaves the others',
        (tester) async {
      provider.filter = const GalleryFilter(
        tagIds: {1},
        date: LastMonthsSelection(1, isJalali: false),
      );
      await pump(tester, GalleryFilterPills(onClearAll: () {}));

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();

      expect(provider.filter.hasTags, isFalse);
      expect(provider.filter.hasDate, isTrue);
    });

    testWidgets('scrolls horizontally on a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, GalleryFilterPills(onClearAll: () {}));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('MoodFilterDialog', () {
    testWidgets('starts with nothing selected and selects on tap',
        (tester) async {
      await pump(tester, const MoodFilterDialog());

      expect(provider.filter.hasMood, isFalse);

      await tester.tap(find.byType(MoodIcon).first);
      await tester.pump();
      expect(provider.filter.moods, {1});

      await tester.tap(find.byType(MoodIcon).last);
      await tester.pump();
      expect(provider.filter.moods, {1, 5});

      await tester.tap(find.byType(MoodIcon).first);
      await tester.pump();
      expect(provider.filter.moods, {5});
    });

    testWidgets('the no mood toggle replaces the selection', (tester) async {
      provider.filter = const GalleryFilter(moods: {1, 2});
      await pump(tester, const MoodFilterDialog());

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(provider.filter.noMood, isTrue);
      expect(provider.filter.moods, isEmpty);
    });
  });

  group('AttachmentFilterDialog', () {
    testWidgets('lists every type unchecked and selects on tap',
        (tester) async {
      await pump(tester, const AttachmentFilterDialog());

      final boxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(boxes.length, AttachmentType.values.length);
      expect(boxes.every((box) => box.value == false), isTrue);

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      expect(
        provider.filter.attachmentTypes,
        {AttachmentType.values.first},
      );
    });
  });

  group('TextFilterDialog', () {
    testWidgets('the no text toggle replaces the terms', (tester) async {
      provider.filter = const GalleryFilter(textTerms: ['sun']);
      await pump(tester, const TextFilterDialog());

      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(provider.filter.noText, isTrue);
      expect(provider.filter.textTerms, isEmpty);
    });

    testWidgets('adds and removes terms, and offers the join for several',
        (tester) async {
      await pump(tester, const TextFilterDialog());

      await tester.enterText(find.byType(TextField), 'sun');
      await tester.tap(find.byTooltip('Add a keyword…'));
      await tester.pump();
      expect(provider.filter.textTerms, ['sun']);
      expect(find.text('All keywords'), findsNothing);

      await tester.enterText(find.byType(TextField), '  rain ');
      await tester.tap(find.byTooltip('Add a keyword…'));
      await tester.pump();
      expect(provider.filter.textTerms, ['sun', 'rain']);
      expect(find.text('All keywords'), findsOneWidget);

      await tester.tap(find.text('Any keyword'));
      await tester.pump();
      expect(provider.filter.textJoin, TextTermJoin.any);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      expect(provider.filter.textTerms, ['rain']);
    });

    testWidgets('a term still in the field is added when the logs are shown',
        (tester) async {
      await pump(tester, const TextFilterDialog());

      await tester.enterText(find.byType(TextField), ' sun ');
      await tester.tap(find.byType(ShowLogsButton));
      await tester.pump();

      expect(provider.filter.textTerms, ['sun']);
    });

    testWidgets('match case is a checkbox', (tester) async {
      await pump(tester, const TextFilterDialog());

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(provider.filter.textMatchCase, isTrue);
    });

    testWidgets('ignores blank and duplicate terms', (tester) async {
      await pump(tester, const TextFilterDialog());

      for (final text in ['   ', 'sun', 'sun']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.tap(find.byTooltip('Add a keyword…'));
        await tester.pump();
      }

      expect(provider.filter.textTerms, ['sun']);
    });
  });
}
