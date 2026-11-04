// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:material_ui/material_ui.dart';

Future<Set<AttachmentType>?> pickExportAttachmentTypes(BuildContext context) {
  final included = {...AttachmentType.values};
  return showAppDialog<Set<AttachmentType>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setLocalState) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.exportIncludeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in AttachmentType.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: included.contains(type),
                title: Text(type.label(AppLocalizations.of(dialogContext)!)),
                onChanged: (value) => setLocalState(() {
                  if (value ?? false) {
                    included.add(type);
                  } else {
                    included.remove(type);
                  }
                }),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, included),
            child: Text(AppLocalizations.of(dialogContext)!.settingsExport),
          ),
        ],
      ),
    ),
  );
}
