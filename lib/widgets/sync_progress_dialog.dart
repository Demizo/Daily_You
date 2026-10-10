// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:daily_you/storage/sync_progress.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/expressive_loading_indicator.dart';
import 'package:daily_you/widgets/sync_item_presentation.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showSyncProgressDialog(
    BuildContext context, ValueListenable<SyncProgress> progress) {
  return showAppDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: SyncProgressDialog(progress: progress),
    ),
  );
}

class SyncProgressDialog extends StatelessWidget {
  const SyncProgressDialog({super.key, required this.progress});

  final ValueListenable<SyncProgress> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<SyncProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            final label = value.item.label(l10n);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExpressiveLoadingIndicator(),
                const SizedBox(height: 20),
                Text(label,
                    style: textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(value.counts ?? ' ',
                    style: textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            );
          },
        ),
      ),
    );
  }
}
