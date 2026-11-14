// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/none_filter_toggle.dart';
import 'package:daily_you/widgets/show_logs_button.dart';
import 'package:material_ui/material_ui.dart';

class GalleryFilterDialog extends StatelessWidget {
  const GalleryFilterDialog({
    super.key,
    required this.title,
    required this.canClear,
    required this.onClear,
    required this.content,
    this.onShowLogs,
    this.noneLabel,
    this.noneValue = false,
    this.onNoneChanged,
  });

  final String title;
  final bool canClear;
  final VoidCallback onClear;
  final Widget content;
  final VoidCallback? onShowLogs;
  final String? noneLabel;
  final bool noneValue;
  final ValueChanged<bool>? onNoneChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final noneLabel = this.noneLabel;
    final onNoneChanged = this.onNoneChanged;

    return AlertDialog(
      scrollable: true,
      title: noneLabel == null || onNoneChanged == null
          ? Text(title)
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text(title),
                NoneFilterToggle(
                  label: noneLabel,
                  value: noneValue,
                  onChanged: onNoneChanged,
                ),
              ],
            ),
      content: SizedBox(
        width: double.maxFinite,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: noneValue ? 0.3 : 1.0,
          child: IgnorePointer(ignoring: noneValue, child: content),
        ),
      ),
      actions: [
        TextButton(
          onPressed: canClear
              ? () {
                  onClear();
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(l10n.clearFilter),
        ),
        ShowLogsButton(onPressed: onShowLogs),
      ],
    );
  }
}
