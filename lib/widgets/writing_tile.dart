// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/widgets/line_limited_text.dart';
import 'package:material_ui/material_ui.dart';

class WritingTile extends StatelessWidget {
  const WritingTile({super.key, required this.summary, this.onTap});

  static const double _verticalPadding = 24;
  static const double _titleHeight = 24;
  static const double _rowHeight = 61;

  static double minimumHeightOf(BuildContext context) =>
      _verticalPadding +
      _titleHeight +
      2 * MediaQuery.textScalerOf(context).scale(_rowHeight);

  final WritingSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;

    Widget cell(num value, String label) => Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCount(value, locale),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Flexible(
                child: LineLimitedText(
                  label,
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );

    return Card.filled(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 10, 12),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text(
                  l10n.statsWritingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ]),
            Expanded(
              child: Row(children: [
                cell(summary.logCount, l10n.statsLogsLabel(summary.logCount)),
                cell(
                    summary.wordCount, l10n.statsWordsLabel(summary.wordCount)),
              ]),
            ),
            Expanded(
              child: Row(children: [
                cell(summary.daysWritten,
                    l10n.statsDaysLabel(summary.daysWritten)),
                cell(
                  summary.averageWordsPerLog.round(),
                  l10n.statsWordsPerLogTitle,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
