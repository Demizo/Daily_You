// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/layouts/window_size_class.dart';
import 'package:daily_you/widgets/no_data_overlay.dart';
import 'package:daily_you/widgets/trend_chip.dart';
import 'package:material_ui/material_ui.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    this.unit,
    this.trend,
    this.valueColor,
    this.bottom,
    this.hasData = true,
    this.onTap,
  });

  static const double _baseHeight = 128;
  static const double graphHeight = 30;
  static const double margin = 4;
  static const double radius = 12;
  static const double _textRowsHeight = 55;
  static const double _noDataFontSize = 15;

  static double heightOf(BuildContext context) =>
      _baseHeight +
      MediaQuery.textScalerOf(context).scale(_textRowsHeight) -
      _textRowsHeight;

  final Widget leading;
  final String title;
  final String value;
  final String? unit;
  final TrendChip? trend;
  final Color? valueColor;
  final Widget? bottom;
  final bool hasData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: const EdgeInsets.all(margin),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: NoDataOverlay(
          hasData: hasData,
          fontSize: _noDataFontSize,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  leading,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: valueColor ?? colorScheme.primary,
                          ),
                        ),
                        if (unit != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: Text(
                              unit!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                    if (trend != null) ...[const SizedBox(width: 8), trend!],
                  ]),
                ),
                const Spacer(),
                if (bottom != null)
                  SizedBox(
                    height: graphHeight,
                    child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: bottom),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatTileGrid extends StatelessWidget {
  const StatTileGrid({super.key, required this.children});

  static const double compactMaxTileWidth = 240;
  static const double wideMaxTileWidth = 330;

  final List<Widget> children;

  static SliverGridDelegate gridDelegateOf(BuildContext context) =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: WindowSizeClass.of(context).isWide
            ? wideMaxTileWidth
            : compactMaxTileWidth,
        mainAxisExtent: StatTile.heightOf(context),
      );

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: gridDelegateOf(context),
      children: children,
    );
  }
}

class StatTileIcon extends StatelessWidget {
  const StatTileIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
}
