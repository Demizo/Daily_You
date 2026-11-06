// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/widgets/day_calendar.dart';
import 'package:material_ui/material_ui.dart';

class LabelCalendarCard extends StatelessWidget {
  const LabelCalendarCard({
    super.key,
    required this.title,
    required this.summary,
    required this.color,
  });

  final String title;
  final LabelSummary summary;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            DayCalendar(
              window: summary.window,
              filledDays: summary.presentDays,
              hasData: hasEnoughChartData(summary.daysPresent),
              filledColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
