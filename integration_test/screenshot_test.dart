import 'dart:async';
import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/language_option.dart';
import 'package:daily_you/main.dart';
import 'package:daily_you/pages/entry_view_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/theme_mode_provider.dart';
import 'package:daily_you/widgets/stats_overview_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../tool/screenshots/locale_mapping.dart';
import '../tool/screenshots/screenshot_device.dart';
import '../tool/screenshots/screenshot_seed_data.dart';

Locale _localeForArbCode(String arbCode) {
  if (arbCode == 'zh_Hant') {
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
  final parts = arbCode.split('_');
  return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
}

Future<void> _settle(WidgetTester tester,
    {Duration timeout = const Duration(seconds: 5)}) async {
  try {
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, timeout);
  } on FlutterError {
    // ignore: empty_catches
  }
}

Future<void> _loadRobotoFont() async {
  final fontLoader = FontLoader('Roboto');
  for (final weight in [
    'Thin',
    'Light',
    'Regular',
    'Medium',
    'Bold',
    'Black'
  ]) {
    fontLoader.addFont(File('tool/screenshots/fonts/Roboto-$weight.ttf')
        .readAsBytes()
        .then(ByteData.sublistView));
  }
  await fontLoader.load();
}

Future<void> _precacheVisibleImages(WidgetTester tester) async {
  final images = tester
      .widgetList<Image>(find.bySubtype<Image>(skipOffstage: true))
      .map((image) => image.image)
      .toSet();
  if (images.isEmpty) return;

  final context = tester.binding.rootElement!;
  await tester.runAsync(
    () => Future.wait(images.map((image) => precacheImage(image, context))),
  );
  await _settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  ScreenshotDevice.screenshotsFolder =
      '../build/screenshots_staging/\$langCode/images/';

  final curatedImagesDirectory = Directory('tool/screenshots/assets');

  setUpAll(() async {
    await _loadRobotoFont();

    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await ConfigProvider.instance.init();
    await AppDatabase.instance.init();
    await ConfigProvider.instance.set(Settings.lastDismissedSupportBannerDate,
        DateTime.now().toIso8601String());
    await ConfigProvider.instance.set(Settings.statsRange, 'sixMonths');

    await DeviceInfoService().init();
  });

  testWidgets('capture fastlane screenshots for every in-scope locale',
      (tester) async {
    debugDefaultTargetPlatformOverride = fastlanePhoneDevice.platform;
    tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
    try {
      final themeModeProvider = ThemeModeProvider();
      await themeModeProvider.initializeThemeFromConfig();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeModeProvider>.value(
              value: themeModeProvider),
          ChangeNotifierProvider<EntriesProvider>.value(
              value: EntriesProvider.instance),
          ChangeNotifierProvider<EntryImagesProvider>.value(
              value: EntryImagesProvider.instance),
          ChangeNotifierProvider<TemplatesProvider>.value(
              value: TemplatesProvider.instance),
          ChangeNotifierProvider<TagsProvider>.value(
              value: TagsProvider.instance),
          ChangeNotifierProvider<ConfigProvider>.value(
              value: ConfigProvider.instance),
        ],
        child: DeviceBox.fromDevice(
          device: fastlanePhoneDevice,
          child: const MainApp(),
        ),
      ));

      final quickLocale = Platform.environment['SCREENSHOT_LOCALE'];
      final arbCodes = quickLocale == null
          ? inScopeArbCodes()
          : inScopeArbCodes().where((code) => code == quickLocale).toList();
      if (arbCodes.isEmpty) {
        throw StateError(
            'SCREENSHOT_LOCALE=$quickLocale is not an in-scope ARB code');
      }

      for (final arbCode in arbCodes) {
        final fastlaneLocale = arbCodeToFastlaneLocale[arbCode]!;
        final locale = _localeForArbCode(arbCode);

        tester.platformDispatcher.localeTestValue = locale;
        tester.platformDispatcher.localesTestValue = [locale];
        await ConfigProvider.instance.set(Settings.overrideLanguage,
            LanguageOption.fromLocale(locale).toJson());

        // Reset entries/images between locales
        await EntriesProvider.instance.deleteAll((_) {});
        await ImageStorage.instance.garbageCollectImages();
        await _settle(tester);

        final l10n = await AppLocalizations.delegate.load(locale);
        await AppDatabase.instance.createWelcomeEntry();
        await ScreenshotSeeder(
          curatedImagesDirectory: curatedImagesDirectory,
          entryText: l10n.welcomeLogBodyText,
        ).seed(DateTime.now());

        await EntriesProvider.instance.load();
        await EntryImagesProvider.instance.load();
        await _settle(tester);

        await _captureHomeAndGallery(tester, themeModeProvider, fastlaneLocale);
        await _captureStats(tester, themeModeProvider, fastlaneLocale);
        await _captureEntryView(tester, themeModeProvider, fastlaneLocale);
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Future<void> _captureHomeAndGallery(WidgetTester tester,
    ThemeModeProvider themeModeProvider, String fastlaneLocale) async {
  themeModeProvider.themeMode = ThemeMode.dark;
  await tester.tap(find.byIcon(Icons.home_rounded));
  await _settle(tester);
  await tester
      .runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
  await _settle(tester);
  await _precacheVisibleImages(tester);
  await tester.expectScreenshot(fastlanePhoneDevice, '1_home',
      langCode: fastlaneLocale);

  themeModeProvider.themeMode = ThemeMode.light;
  await tester.tap(find.byIcon(Icons.photo_library_rounded));
  await _settle(tester);
  await _precacheVisibleImages(tester);
  await tester.expectScreenshot(fastlanePhoneDevice, '2_gallery',
      langCode: fastlaneLocale);
}

Future<void> _captureStats(WidgetTester tester,
    ThemeModeProvider themeModeProvider, String fastlaneLocale) async {
  themeModeProvider.themeMode = ThemeMode.dark;
  await tester.tap(find.byIcon(Icons.auto_graph_rounded));
  await _settle(tester);

  final scrollable = tester.state<ScrollableState>(find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byWidgetPredicate((widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up))));
  scrollable.position.jumpTo(0);
  await _settle(tester);

  final overviewCardHeight =
      tester.getSize(find.byType(StatsOverviewCard)).height;
  scrollable.position.jumpTo(overviewCardHeight);
  await _settle(tester);

  await tester.expectScreenshot(fastlanePhoneDevice, '3_stats',
      langCode: fastlaneLocale);
}

Future<void> _captureEntryView(WidgetTester tester,
    ThemeModeProvider themeModeProvider, String fastlaneLocale) async {
  themeModeProvider.themeMode = ThemeMode.light;
  final welcomeEntry =
      EntriesProvider.instance.entries.reduce((a, b) => a.id! < b.id! ? a : b);

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  // Navigator.push only resolves when the route is popped, so awaiting it
  // here would deadlock before the pop() below ever runs.
  unawaited(navigator.push(MaterialPageRoute<void>(
    builder: (_) => EntryViewPage(
      entryId: welcomeEntry.id!,
      onEntryEdited: (_) {},
    ),
  )));
  await _settle(tester);
  await _precacheVisibleImages(tester);
  await tester.expectScreenshot(fastlanePhoneDevice, '4_entry_view',
      langCode: fastlaneLocale);

  navigator.pop();
  await _settle(tester);
}
