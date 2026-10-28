// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/pages/settings/storage_settings.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../support/config_provider_harness.dart';

void main() {
  useTemporaryConfig();

  Future<void> pumpPage(WidgetTester tester) async {
    changeSetting(Settings.logSyncFolderUri, '/storage/Journal');
    changeSetting(Settings.syncLogs, true);
    changeSetting(Settings.syncImages, true);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: ConfigProvider.instance,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StorageSettings(),
        ),
      ),
    );
  }

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  Future<void> turnImagesOffInSyncOptions(WidgetTester tester) async {
    await pumpPage(tester);
    expect(find.text('Journal'), findsOneWidget);

    await tester.tap(find.text('Sync with External Location'));
    await tester.pumpAndSettle();
    expect(inDialog(find.text('Journal/Images')), findsOneWidget);

    await tester.tap(find.descendant(
        of: find
            .ancestor(
                of: inDialog(find.text('Images')), matching: find.byType(Row))
            .first,
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();
  }

  testWidgets('applies staged sync options on OK', (tester) async {
    await turnImagesOffInSyncOptions(tester);
    expect(ConfigProvider.instance.get(Settings.syncImages), isTrue);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    EasyDebounce.cancel('save-config');

    expect(ConfigProvider.instance.get(Settings.syncImages), isFalse);
  });

  testWidgets('discards staged sync options on Cancel', (tester) async {
    await turnImagesOffInSyncOptions(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(ConfigProvider.instance.get(Settings.syncImages), isTrue);
  });

  testWidgets('turns sync off from the switch without opening its options',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    EasyDebounce.cancel('save-config');

    expect(find.byType(AlertDialog), findsNothing);
    expect(ExternalSyncSettings.load().isOn, isFalse);
  });

  testWidgets('shows a chip for every attachment type before sizes load',
      (tester) async {
    await pumpPage(tester);

    expect(find.byType(Chip), findsNWidgets(AttachmentType.values.length));
  });

  testWidgets('keeps vertical spacing between wrapped chips', (tester) async {
    tester.view.physicalSize = const Size(340, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPage(tester);

    final rects = [
      for (final chip in tester.widgetList(find.byType(Chip)))
        tester.getRect(find.byWidget(chip)),
    ];
    expect(rects[1].top, greaterThan(rects[0].top));
    expect(rects[1].top - rects[0].bottom, greaterThanOrEqualTo(8));
  });
}
