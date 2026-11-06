// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/utils/secondary_text_style.dart';
import 'package:daily_you/widgets/mood_tier_bar.dart';
import 'package:daily_you/widgets/mood_tier_mark.dart';
import 'package:daily_you/widgets/no_data_overlay.dart';
import 'package:material_ui/material_ui.dart';

class MoodSummaryChart extends StatelessWidget {
  const MoodSummaryChart({
    super.key,
    required this.tierCounts,
    required this.hasData,
  });

  static const List<int> _previewTierCounts = [2, 5, 9, 7, 3];
  static const double _markSize = 34;

  final List<int> tierCounts;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final counts = hasData ? tierCounts : _previewTierCounts;
    final total = counts.fold(0, (sum, count) => sum + count);
    final highest = counts.reduce(math.max);

    return Card.filled(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                l10n.chartSummaryTitle(l10n.tagMoodTitle),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          NoDataOverlay(
            hasData: hasData,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(children: [
                MoodTierBar(
                  shares: [
                    for (final count in counts) total == 0 ? 0 : count / total,
                  ],
                ),
                const SizedBox(height: 14),
                Row(children: [
                  for (final (position, count) in counts.indexed)
                    Expanded(
                      child: _MoodCount(
                        mood: Mood.fromPosition(position),
                        count: count,
                        isHighest: count > 0 && count == highest,
                      ),
                    ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCount extends StatelessWidget {
  const _MoodCount({
    required this.mood,
    required this.count,
    required this.isHighest,
  });

  final int mood;
  final int count;
  final bool isHighest;

  @override
  Widget build(BuildContext context) {
    final style = secondaryTextStyle(context, fontSize: 14);
    return Column(children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: MoodTierMark(mood: mood, size: MoodSummaryChart._markSize),
      ),
      const SizedBox(height: 6),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          formatCount(count, AppLocalizations.of(context)!.localeName),
          style: isHighest
              ? style.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                )
              : style,
        ),
      ),
    ]);
  }
}
