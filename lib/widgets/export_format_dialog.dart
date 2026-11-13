// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/exports/export_registry.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:material_ui/material_ui.dart';

Future<ExportFormatOption?> showExportFormatDialog(
  BuildContext context, {
  bool showWarning = true,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showSettingsDialog<ExportFormatOption>(
    context: context,
    title: l10n.logFormatTitle,
    isSelection: true,
    builder: (context) => [
      if (showWarning)
        SettingsInfoRow(
            title: l10n.warningTitle,
            subtitle: Text(l10n.settingsExportFormatDescription)),
      for (final option in ExportRegistry.instance.options)
        SettingsActionRow(
          title: option.name(l10n),
          onTap: () => Navigator.of(context).pop(option),
        ),
    ],
  );
}
