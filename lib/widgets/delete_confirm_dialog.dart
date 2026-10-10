// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

/// Delete confirmation prompt. Returns true when a delete is confirmed, false otherwise.
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AppLocalizations.of(dialogContext)!.deleteTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child:
              Text(MaterialLocalizations.of(dialogContext).deleteButtonTooltip),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child:
              Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
