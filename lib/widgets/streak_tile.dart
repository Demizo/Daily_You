// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/count_format.dart';
import 'package:daily_you/widgets/flame_badge.dart';
import 'package:daily_you/widgets/morphing_burst.dart';
import 'package:material_ui/material_ui.dart';

class StreakTile extends StatelessWidget {
  const StreakTile({super.key, required this.streak, this.onTap});

  static const double _numberScale = 0.36;
  static const double _labelFontSize = 14;
  static const double _labelGap = 2;

  final int streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageBackground = Theme.of(context).scaffoldBackgroundColor;
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final textScaler = MediaQuery.textScalerOf(context);
    final numberText = formatCount(streak, l10n.localeName);
    final labelStyle = TextStyle(
      fontSize: _labelFontSize,
      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
    );
    final labelHeight = (TextPainter(
      text: TextSpan(
        text: l10n.streakDayLabel(streak),
        style: DefaultTextStyle.of(context).style.merge(labelStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout())
        .height;

    return LayoutBuilder(builder: (context, constraints) {
      final side = constraints.biggest.shortestSide;
      final badgeSize = side * 0.36;
      final cutoutSize = badgeSize * 1.34;
      final badgeCenter = Offset(side * (isRtl ? 0.27 : 0.73), side * 0.27);
      final inset = side * 0.1;
      final bottomInset = side * 0.09;
      final clearance = side * 0.02;

      final fullSize = side * _numberScale;
      final fullWidth = (TextPainter(
        text: TextSpan(
          text: numberText,
          style: TextStyle(fontSize: fullSize, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout())
          .width;
      final cutoutEdge = isRtl
          ? side - (badgeCenter.dx + cutoutSize / 2)
          : badgeCenter.dx - cutoutSize / 2;
      final beside =
          fullSize * math.min(1, (cutoutEdge - inset - clearance) / fullWidth);
      final below = math.min(
        fullSize * math.min(1, (side - 2 * inset) / fullWidth),
        side -
            bottomInset -
            labelHeight -
            _labelGap -
            clearance -
            (badgeCenter.dy + cutoutSize / 2),
      );

      return Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(side * 0.15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(children: [
            Positioned(
              left: badgeCenter.dx - cutoutSize / 2,
              top: badgeCenter.dy - cutoutSize / 2,
              width: cutoutSize,
              height: cutoutSize,
              child: CustomPaint(
                painter:
                    MorphingBurstPainter(progress: 1, color: pageBackground),
              ),
            ),
            Positioned(
              left: badgeCenter.dx - badgeSize / 2,
              top: badgeCenter.dy - badgeSize / 2,
              child: FlameBadge(
                size: badgeSize,
                color: colorScheme.primary,
                flameColor: colorScheme.onPrimary,
              ),
            ),
            PositionedDirectional(
              start: inset,
              bottom: bottomInset,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    numberText,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: math.max(beside, below),
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: _labelGap),
                  Text(l10n.streakDayLabel(streak), style: labelStyle),
                ],
              ),
            ),
          ]),
        ),
      );
    });
  }
}
