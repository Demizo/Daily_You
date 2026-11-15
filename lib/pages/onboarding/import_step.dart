// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/pages/onboarding/onboarding_illustrations.dart';
import 'package:daily_you/pages/onboarding/onboarding_scope.dart';
import 'package:daily_you/pages/onboarding/onboarding_step_layout.dart';
import 'package:daily_you/pages/onboarding/onboarding_tile.dart';
import 'package:daily_you/utils/import_flow.dart';
import 'package:daily_you/utils/restore_flow.dart';
import 'package:material_ui/material_ui.dart';

class ImportStep extends StatefulWidget {
  const ImportStep({super.key, required this.index});

  final int index;

  @override
  State<ImportStep> createState() => _ImportStepState();
}

class _ImportStepState extends State<ImportStep> {
  bool _imported = false;

  Future<void> _import() async {
    final outcome = await ImportFlow.run(context);
    if (mounted && outcome.succeeded) setState(() => _imported = true);
  }

  Future<void> _restore() async {
    final scope = OnboardingScope.of(context);
    final outcome = await RestoreFlow.run(context);
    if (outcome.succeeded) scope.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OnboardingStepLayout(
      index: widget.index,
      illustration: const OnboardingIllustration(icon: Icons.menu_book_rounded),
      title: l10n.onboardingImportTitle,
      description: l10n.onboardingImportDescription,
      children: [
        OnboardingTile.task(
          icon: Icons.download_rounded,
          title: l10n.settingsImportFromAnotherApp,
          done: _imported,
          onTap: _import,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _restore,
          child: Text(l10n.onboardingRestore),
        ),
      ],
    );
  }
}
