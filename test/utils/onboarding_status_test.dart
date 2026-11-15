// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/onboarding_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  final configProvider = ConfigProvider.instance;

  test('a new install without a database is pending', () async {
    expect(await OnboardingStatus.isPending(databaseExisted: false), isTrue);
    expect(configProvider.get(Settings.onboardingCompleted), isFalse);
  });

  test('an install that stays unfinished remains pending', () async {
    await OnboardingStatus.isPending(databaseExisted: false);

    expect(await OnboardingStatus.isPending(databaseExisted: true), isTrue);
  });

  test('an existing database counts as completed', () async {
    expect(await OnboardingStatus.isPending(databaseExisted: true), isFalse);
    expect(configProvider.get(Settings.onboardingCompleted), isTrue);
  });

  test('completing onboarding stops it from showing', () async {
    await OnboardingStatus.isPending(databaseExisted: false);
    await OnboardingStatus.complete();

    expect(await OnboardingStatus.isPending(databaseExisted: false), isFalse);
  });
}
