// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';

Future<bool?> showPartialMatchesDialog(
  BuildContext context, {
  required int partialMatchCount,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        title: Text(l10n.gallerySelectAll),
        content: Text(l10n.selectPartialMatchesMessage(partialMatchCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.selectExactMatchesOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.selectIncludingPartialMatches),
          ),
        ],
      );
    },
  );
}
