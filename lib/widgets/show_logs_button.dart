// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class ShowLogsButton extends StatelessWidget {
  const ShowLogsButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final resultCount = context.select<EntriesProvider, int>(
      (provider) => provider.getFilteredEntries().length,
    );
    return FilledButton(
      onPressed: () {
        onPressed?.call();
        Navigator.of(context).pop();
      },
      child: Text(AppLocalizations.of(context)!.showLogsCount(resultCount)),
    );
  }
}
