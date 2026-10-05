// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class MediaErrorView extends StatelessWidget {
  const MediaErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.attachmentLoadFailed,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
