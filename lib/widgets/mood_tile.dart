// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/utils/bucket_combiner.dart';
import 'package:daily_you/widgets/mood_tier_bar.dart';
import 'package:daily_you/widgets/mood_tier_mark.dart';
import 'package:daily_you/widgets/value_over_time_chart.dart';
import 'package:material_ui/material_ui.dart';

class MoodTile extends StatelessWidget {
  const MoodTile({super.key, required this.summary, this.onTap});

  final MoodSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card.filled(
      margin: const EdgeInsets.all(4),
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
          child: Column(children: [
            Stack(
              children: [
                Center(
                  child: Text(
                    l10n.tagMoodTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant),
                ]),
              ],
            ),
            const SizedBox(height: 4),
            ValueOverTimeChart.compact(
              dataPoints: summary.dayMeans,
              hasData: hasEnoughChartData(summary.dayMeans.length),
              yRange: MoodTierMark.axisRange,
              combine: combineByAverage,
              leftAxisWidth: MoodTierMark.axisWidth,
              buildLeftTitle: MoodTierMark.axisTitle,
            ),
            MoodTierBar(shares: summary.tierShares),
          ]),
        ),
      ),
    );
  }
}
