// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_page.dart';
import 'package:daily_you/pages/onboarding/onboarding_scope.dart';
import 'package:daily_you/pages/onboarding/welcome_step.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  late ThemeModeProvider themeProvider;

  Future<void> pumpPage(WidgetTester tester, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    themeProvider = ThemeModeProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ConfigProvider.instance),
          ChangeNotifierProvider.value(value: MoodScaleProvider.instance),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingPage(nextPage: Text('main app')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> settlePageChange(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('opens on the welcome page with the first check filled',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('Welcome to Daily You'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets(
      'continue moves through the pages and the last page offers to start journaling',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);
    expect(find.text('Coming from another app?'), findsOneWidget);
    expect(find.text('Import From Another App'), findsOneWidget);
    expect(find.text('Restore from a backup'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);
    expect(find.text('Keep your logs safe'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Start journaling'), findsOneWidget);
    expect(find.text('Sync with External Location'), findsOneWidget);
    expect(
        find.text('You can change these later in Settings.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('page content is drawn as snapshots only while changing pages',
      (tester) async {
    await pumpPage(tester);

    bool snapshotting() => tester
        .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
        .any((widget) => widget.controller.allowSnapshotting);

    expect(snapshotting(), isFalse);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(snapshotting(), isTrue);

    await tester.pump(const Duration(milliseconds: 600));
    expect(snapshotting(), isFalse);
  });

  testWidgets('the ambient motion holds still while changing pages',
      (tester) async {
    await pumpPage(tester);
    final ambient =
        OnboardingScope.of(tester.element(find.byType(WelcomeStep))).ambient;

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final heldValue = ambient.value;
    await tester.pump(const Duration(milliseconds: 400));
    expect(ambient.value, heldValue);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    expect(ambient.value, isNot(heldValue));
  });

  testWidgets('the theme buttons change the app theme', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pump();

    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(ConfigProvider.instance.get(Settings.theme), 'dark');
    EasyDebounce.cancel('save-config');
  });

  testWidgets('skip completes onboarding and opens the app', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('main app'), findsOneWidget);
    expect(ConfigProvider.instance.get(Settings.onboardingCompleted), isTrue);
    EasyDebounce.cancel('save-config');
  });

  testWidgets('start journaling on the last page completes onboarding',
      (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);
    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);

    await tester.tap(find.text('Start journaling'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('main app'), findsOneWidget);
    expect(ConfigProvider.instance.get(Settings.onboardingCompleted), isTrue);
    EasyDebounce.cancel('save-config');
  });

  testWidgets('keeps a single footer button while a page is dragged',
      (tester) async {
    await pumpPage(tester);

    await tester.drag(find.byType(PageView), const Offset(-200, 0));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('two quick taps on continue advance a single page',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    await settlePageChange(tester);

    expect(find.text('Coming from another app?'), findsOneWidget);
  });

  testWidgets('skip stays on the last page and finishes onboarding',
      (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);
    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('main app'), findsOneWidget);
    EasyDebounce.cancel('save-config');
  });

  testWidgets('keeps the skip button in place on every page', (tester) async {
    await pumpPage(tester);
    final welcomeOffset = tester.getTopLeft(find.text('Skip'));
    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);
    await tester.tap(find.text('Continue'));
    await settlePageChange(tester);

    expect(tester.getTopLeft(find.text('Skip')), welcomeOffset);
  });

  testWidgets('lays out on a wide desktop window', (tester) async {
    await pumpPage(tester, size: const Size(1280, 720));

    expect(find.text('Welcome to Daily You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out on a short phone window', (tester) async {
    await pumpPage(tester, size: const Size(360, 520));

    expect(find.text('Welcome to Daily You'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
