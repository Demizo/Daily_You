// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/widgets/flame_badge.dart';
import 'package:material_ui/material_ui.dart';

class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.recentDaysWritten,
  });

  final int currentStreak;
  final int longestStreak;
  final List<bool> recentDaysWritten;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 8,
            runSpacing: 12,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                FlameBadge(
                  size: 72,
                  color: colorScheme.primary,
                  flameColor: colorScheme.onPrimary,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCount(currentStreak, l10n.localeName),
                      style: TextStyle(
                        fontSize: 48,
                        height: 1,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      l10n.streakDayLabel(currentStreak),
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ]),
              _Pill(
                label: l10n.statsLongestStreakTitle,
                value: formatCount(longestStreak, l10n.localeName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final visibleCount = math.min(
              recentDaysWritten.length,
              (constraints.maxWidth / _DayDot._slotSize).floor(),
            );
            final visibleDays = recentDaysWritten.sublist(
              recentDaysWritten.length - visibleCount,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (index, written) in visibleDays.indexed)
                  _DayDot(
                    written: written,
                    isToday: index == visibleDays.length - 1,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              label,
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.written, required this.isToday});

  static const double _dotSize = 15;
  static const double _slotSize = 21;

  final bool written;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: written ? colorScheme.primary : Colors.transparent,
              border: written
                  ? null
                  : Border.all(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.35),
                      width: 1.5,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
