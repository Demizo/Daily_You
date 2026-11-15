// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/pages/onboarding/onboarding_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every step is offered when reminders are supported', () {
    expect(OnboardingStep.sequence(includesReminders: true), [
      OnboardingStep.welcome,
      OnboardingStep.importData,
      OnboardingStep.reminders,
      OnboardingStep.storage,
    ]);
  });

  test('the reminders step is dropped when reminders are not supported', () {
    expect(OnboardingStep.sequence(includesReminders: false), [
      OnboardingStep.welcome,
      OnboardingStep.importData,
      OnboardingStep.storage,
    ]);
  });
}
