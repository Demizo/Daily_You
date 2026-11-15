// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_step_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingFooter extends StatelessWidget {
  static const double _height = 48;

  const OnboardingFooter({
    super.key,
    required this.stepCount,
    required this.position,
    required this.onNext,
    required this.onFinish,
  });

  final int stepCount;
  final ValueListenable<double> position;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: OnboardingStepLayout.maxWidth),
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: ValueListenableBuilder<double>(
            valueListenable: position,
            builder: (context, value, _) {
              final isLast = value.round() == stepCount - 1;
              return FilledButton(
                onPressed: isLast ? onFinish : onNext,
                child: Text(
                    isLast ? l10n.onboardingFinish : l10n.onboardingContinue),
              );
            },
          ),
        ),
      ),
    );
  }
}
