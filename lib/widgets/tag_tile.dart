// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/frequency_bars.dart';
import 'package:daily_you/widgets/sparkline.dart';
import 'package:daily_you/widgets/stat_tile.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:daily_you/widgets/trend_chip.dart';
import 'package:material_ui/material_ui.dart';

const List<double> _previewFrequencies = [
  3,
  5,
  2,
  4,
  6,
  3,
  1,
  4,
  5,
  7,
  4,
  3,
];

const List<double?> _previewSparkline = [
  3.4,
  3.9,
  3.5,
  4.4,
  4,
  3.6,
  4.2,
  5,
  4.6,
  4.9,
  4.3,
  4.7,
];

class TagTile extends StatelessWidget {
  const TagTile({
    super.key,
    required this.tag,
    required this.summary,
    this.onTap,
  });

  final Tag tag;
  final TagTileSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final color = tag.resolvedColor(context);
    final value = summary.value;
    final isLabel = tag.tagType == TagType.label;

    return StatTile(
      leading: TagIconGlyph(
        icon: tag.icon,
        iconType: tag.iconType,
        fallbackIcon: tag.typeIcon,
        color: color,
        size: 18,
      ),
      title: tag.name,
      value: value == null
          ? ''
          : isLabel
              ? formatPercent(value, locale)
              : formatDecimal(value, locale),
      unit: value == null
          ? null
          : isLabel
              ? l10n.statsOfDaysLabel
              : l10n.statsAverageTitle,
      valueColor: color,
      trend: TrendChip.fromChange(
        summary.trend,
        (amount) => isLabel
            ? formatPercent(amount / 100, locale)
            : formatDecimal(amount, locale),
      ),
      hasData: value != null,
      bottom: isLabel
          ? FrequencyBars(
              values: value == null
                  ? _previewFrequencies
                  : [for (final count in summary.series) count ?? 0],
              color: color,
            )
          : Sparkline(
              values: value == null ? _previewSparkline : summary.series,
              color: color,
              minimum: 0,
            ),
      onTap: onTap,
    );
  }
}
