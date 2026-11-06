// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/no_data_overlay.dart';
import 'package:daily_you/widgets/trend_chip.dart';
import 'package:material_ui/material_ui.dart';

class StatHeadlineItem {
  const StatHeadlineItem({
    required this.label,
    required this.text,
    this.trend,
  });

  final String label;
  final String text;
  final TrendChip? trend;
}

class StatHeadlineCard extends StatelessWidget {
  const StatHeadlineCard({
    super.key,
    required this.items,
    required this.accentColor,
    this.hasData = true,
  });

  static const double _valueHeight = 34;

  final List<StatHeadlineItem> items;
  final Color accentColor;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.filled(
      color: colorScheme.surfaceContainerLow,
      child: NoDataOverlay(
        hasData: hasData,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, item) in items.indexed)
                Expanded(
                  child: _HeadlineValue(
                    item: item,
                    color: index == 0 ? accentColor : colorScheme.onSurface,
                    height: _valueHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeadlineValue extends StatelessWidget {
  const _HeadlineValue({
    required this.item,
    required this.color,
    required this.height,
  });

  final StatHeadlineItem item;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (item.trend != null) ...[
                  const SizedBox(width: 6),
                  item.trend!,
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
