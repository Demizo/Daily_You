// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/stats/stats_range.dart';
import 'package:daily_you/widgets/content_width_limit.dart';
import 'package:daily_you/widgets/stat_range_selector.dart';
import 'package:material_ui/material_ui.dart';

class SliverStatsRangeHeader extends StatelessWidget {
  const SliverStatsRangeHeader({super.key, required this.statsRange});

  final StatsRange statsRange;

  @override
  Widget build(BuildContext context) {
    final prototype = _RangeHeader(
      statsRange: statsRange,
      onRangeChanged: (_) {},
    );
    return SliverResizingHeader(
      minExtentPrototype: prototype,
      maxExtentPrototype: prototype,
      child: ContentWidthLimit(
        child: _RangeHeader(
          statsRange: statsRange,
          onRangeChanged: ConfigProvider.instance.setStatsRange,
        ),
      ),
    );
  }
}

class _RangeHeader extends StatelessWidget {
  const _RangeHeader({required this.statsRange, required this.onRangeChanged});

  static const double _fadeHeight = 8;

  final StatsRange statsRange;
  final ValueChanged<StatsRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: StatsRangeSelector(
            statsRange: statsRange,
            onSelectionChanged: onRangeChanged,
          ),
        ),
      ),
      Container(
        height: _fadeHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, backgroundColor.withValues(alpha: 0)],
          ),
        ),
      ),
    ]);
  }
}
