// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';

Future<bool> confirmDatabaseOverwrite(BuildContext context, String uri,
    {Future<bool> Function(String uri)? hasDatabase}) async {
  if (!await (hasDatabase ?? AppDatabase.instance.hasExternalDatabase)(uri)) {
    return true;
  }
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.warningTitle),
      content: Text(l10n.logFolderWarningDescription),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
