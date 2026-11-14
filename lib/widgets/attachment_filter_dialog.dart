// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/utils/filter_selection.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/gallery_filter_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AttachmentFilterDialog extends StatelessWidget {
  const AttachmentFilterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<EntriesProvider>();
    final filter = provider.filter;

    return GalleryFilterDialog(
      title: l10n.filterPillAttachments,
      canClear: filter.hasAttachments,
      onClear: () => provider.filter = filter.withoutAttachments(),
      noneLabel: l10n.noAttachmentsFilterLabel,
      noneValue: filter.noAttachments,
      onNoneChanged: (value) => provider.filter = filter.copyWith(
        noAttachments: value,
        attachmentTypes: value ? const {} : filter.attachmentTypes,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final type in AttachmentType.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(type.icon),
              title: Text(type.label(l10n)),
              value: filter.attachmentTypes.contains(type),
              onChanged: (_) => provider.filter = filter.copyWith(
                attachmentTypes: toggledSelection(filter.attachmentTypes, type),
              ),
            ),
        ],
      ),
    );
  }
}
