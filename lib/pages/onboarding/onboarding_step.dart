// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

enum OnboardingStep {
  welcome,
  importData,
  reminders,
  storage;

  static List<OnboardingStep> sequence({required bool includesReminders}) => [
        for (final step in values)
          if (step != reminders || includesReminders) step,
      ];
}
