// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/widgets/connected_button_group.dart';
import 'package:daily_you/widgets/stats_range_labels.dart';

class StatsRangeSelector extends StatelessWidget {
  static const double _wideTopPadding = 12;

  final StatsRange statsRange;
  final Function(StatsRange newSelection) onSelectionChanged;
  const StatsRangeSelector(
      {super.key, required this.statsRange, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        top: WindowSizeClass.of(context).isWide ? _wideTopPadding : 0,
      ),
      child: ConnectedButtonGroup(
        labels: [for (final range in StatsRange.values) range.label(l10n)],
        selectedIndex: StatsRange.values.indexOf(statsRange),
        onSelectionChanged: (index) =>
            onSelectionChanged(StatsRange.values[index]),
      ),
    );
  }
}
