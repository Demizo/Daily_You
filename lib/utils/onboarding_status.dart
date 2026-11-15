// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';

abstract final class OnboardingStatus {
  static Future<bool> isPending({required bool databaseExisted}) async {
    final configProvider = ConfigProvider.instance;
    final completed = configProvider.get(Settings.onboardingCompleted);
    if (completed != null) return !completed;

    await configProvider.set(Settings.onboardingCompleted, databaseExisted);
    return !databaseExisted;
  }

  static Future<void> complete() =>
      ConfigProvider.instance.set(Settings.onboardingCompleted, true);
}
