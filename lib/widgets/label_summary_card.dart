import 'package:daily_you/models/tag.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

class LabelSummaryCard extends StatelessWidget {
  final Tag tag;
  final int presentCount;
  final int totalCount;

  const LabelSummaryCard({
    super.key,
    required this.tag,
    required this.presentCount,
    required this.totalCount,
  });

  double get _coverage => totalCount > 0 ? presentCount / totalCount : 0;
  int get _absentCount => totalCount - presentCount;
  bool get _hasData => totalCount > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagColor = tag.resolvedColor(context);
    final coverageText = '${(_coverage * 100).toStringAsFixed(1)}%';
    final hasIcon = tag.icon != null && tag.icon!.isNotEmpty;

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Center(
              child: Text(
                l10n.chartSummaryTitle(tag.name),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _hasData ? 1.0 : 0.3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasIcon)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: TagIconGlyph(
                                  icon: tag.icon,
                                  iconType: tag.iconType,
                                  fallbackIcon: tag.typeIcon,
                                  color: tagColor,
                                  size: 30,
                                  characterSize: 36,
                                ),
                              ),
                            Text(
                              coverageText,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: tagColor,
                              ),
                            ),
                            Text(
                              l10n.labelCoverageLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatRow(
                              label: l10n.labelPresentLabel,
                              count: presentCount,
                              color: tagColor,
                            ),
                            const SizedBox(height: 8),
                            _StatRow(
                              label: l10n.labelAbsentLabel,
                              count: _absentCount,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_hasData)
                Text(
                  l10n.statisticsNotEnoughData,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
