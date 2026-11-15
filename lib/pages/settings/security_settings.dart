// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/app_lock_rows.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class SecuritySettings extends StatelessWidget {
  const SecuritySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.watch<ConfigProvider>();

    return SettingsPageScaffold(
      title: l10n.settingsSecurityTitle,
      children: [
        SegmentedGroup(children: [
          AppLockRows.requirePassword(context),
          ...AppLockRows.biometricUnlock(context),
        ]),
      ],
    );
  }
}
