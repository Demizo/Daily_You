// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_scope.dart';
import 'package:daily_you/pages/onboarding/reminders_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  Future<void> pumpStep(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: ConfigProvider.instance,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScope(
            ambient: const AlwaysStoppedAnimation(0),
            position: ValueNotifier(0),
            transitioning: ValueNotifier(false),
            onFinish: () {},
            child: const Scaffold(body: RemindersStep(index: 0)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder findText(String text) => find.byWidgetPredicate((widget) =>
      widget is Text && widget.data?.replaceAll('\u202f', ' ') == text);

  testWidgets('hides the reminder time until reminders are on', (tester) async {
    await pumpStep(tester);

    expect(find.text('Daily Reminder'), findsOneWidget);
    expect(findText('9:00 PM'), findsNothing);
  });

  testWidgets('shows a fixed reminder time as a single time', (tester) async {
    changeSetting(Settings.dailyReminders, true);
    changeSetting(Settings.setReminderTime, true);
    changeSetting(Settings.scheduledReminderHour, 21);
    await pumpStep(tester);

    expect(findText('9:00 PM'), findsOneWidget);
  });

  testWidgets('shows the window as start then end', (tester) async {
    changeSetting(Settings.dailyReminders, true);
    await pumpStep(tester);

    expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            (widget.data?.replaceAll('\u202f', ' ').contains('9:00 AM') ??
                false) &&
            widget.data!.replaceAll('\u202f', ' ').contains('9:00 PM')),
        findsOneWidget);
  });
}
