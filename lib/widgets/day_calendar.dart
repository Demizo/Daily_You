// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/stats/stats_analysis.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/day_grid_layout.dart';
import 'package:daily_you/widgets/animated_values.dart';
import 'package:daily_you/widgets/no_data_overlay.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class DayCalendar extends StatelessWidget {
  const DayCalendar({
    super.key,
    required this.window,
    required this.filledDays,
    this.filledColor,
    this.hasData = true,
  });

  static const double _monthLabelHeight = 18;
  static const double _rowLabelWidth = 22;
  static const double _labelFontSize = 12;

  final StatsWindow window;
  final Set<DateTime> filledDays;
  final Color? filledColor;
  final bool hasData;

  static double _previewNoise(int index) {
    var hash = (index + 1) * 2654435761 & 0xffffffff;
    hash = (hash ^ (hash >> 15)) * 2246822519 & 0xffffffff;
    hash = (hash ^ (hash >> 13)) & 0xffff;
    return hash / 0xffff;
  }

  static double _previewEngagement(int dayIndex) {
    const span = 5;
    final blend = (dayIndex % span) / span;
    final eased = blend * blend * (3 - 2 * blend);
    final previous = _previewNoise(dayIndex ~/ span);
    final next = _previewNoise(dayIndex ~/ span + 1);
    return previous + (next - previous) * eased;
  }

  static Set<DateTime> _previewDays(StatsWindow window) => {
        for (var dayIndex = 0; dayIndex < window.dayCount; dayIndex++)
          if (_isPreviewDay(window, dayIndex)) _dateOf(window, dayIndex),
      };

  static DateTime _dateOf(StatsWindow window, int dayIndex) => DateTime(
        window.start.year,
        window.start.month,
        window.start.day + dayIndex,
      );

  static bool _isPreviewDay(StatsWindow window, int dayIndex) {
    final isWeekend = _dateOf(window, dayIndex).weekday >= DateTime.saturday;
    final score = _previewEngagement(dayIndex) * 0.5 +
        _previewNoise(dayIndex + 7919) * 0.5 -
        (isWeekend ? 0.15 : 0);
    return score > 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstWeekday = context.select<ConfigProvider, int>(
            (config) => config.getFirstDayOfWeekIndex(context)) +
        1;
    final isJalali = TimeManager.isJalaliCalendar(context);
    final labelStyle = DefaultTextStyle.of(context).style.copyWith(
        fontSize: _labelFontSize, color: colorScheme.onSurfaceVariant);

    final calendar = LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth - _rowLabelWidth;
      const cellSize = DayGridLayout.cellSize;
      final layout = DayGridLayout(
        start: window.start,
        dayCount: window.dayCount,
        firstWeekday: firstWeekday,
        minimumWeekCount: DayGridLayout.weekCountFor(availableWidth),
      );
      final grid = CustomPaint(
        size:
            Size(cellSize * layout.weekCount, _monthLabelHeight + 7 * cellSize),
        painter: _DayCalendarPainter(
          layout: layout,
          filledDays: hasData ? filledDays : _previewDays(window),
          cellSize: cellSize,
          monthLabelHeight: _monthLabelHeight,
          isRtl: Directionality.of(context) == TextDirection.rtl,
          monthLabels: [
            for (final label in layout.monthLabels(isJalali: isJalali))
              (
                column: label.column,
                text: TimeManager.formatMonthName(label.date, context)
              ),
          ],
          filledColor: filledColor ?? colorScheme.primary,
          emptyColor: colorScheme.surfaceContainerHighest,
          disabledColor:
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          labelStyle: labelStyle,
        ),
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _rowLabelWidth,
            height: _monthLabelHeight + 7 * cellSize,
            child: Stack(children: [
              for (final row in layout.labeledRows)
                PositionedDirectional(
                  start: 0,
                  top: _monthLabelHeight + row * cellSize,
                  height: cellSize,
                  child: Center(
                    child: Text(
                      TimeManager.formatNarrowWeekday(
                          layout.weekdayOfRow(row), context),
                      style: labelStyle,
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: cellSize * layout.weekCount <= availableWidth
                ? Align(
                    alignment: AlignmentDirectional.centerStart, child: grid)
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: grid,
                  ),
          ),
        ],
      );
    });

    return NoDataOverlay(
      hasData: hasData,
      child: AnimatedSize(
        duration: statsAnimationDuration,
        curve: statsAnimationCurve,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: statsAnimationDuration,
          switchInCurve: statsAnimationCurve,
          switchOutCurve: statsAnimationCurve,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [
              for (final outgoing in previous)
                Positioned(top: 0, left: 0, right: 0, child: outgoing),
              if (current != null) current,
            ],
          ),
          child: KeyedSubtree(
            key: ValueKey((window.start, window.dayCount)),
            child: calendar,
          ),
        ),
      ),
    );
  }
}

class _DayCalendarPainter extends CustomPainter {
  _DayCalendarPainter({
    required this.layout,
    required this.filledDays,
    required this.cellSize,
    required this.monthLabelHeight,
    required this.isRtl,
    required this.monthLabels,
    required this.filledColor,
    required this.emptyColor,
    required this.disabledColor,
    required this.labelStyle,
  });

  final DayGridLayout layout;
  final Set<DateTime> filledDays;
  final double cellSize;
  final double monthLabelHeight;
  final bool isRtl;
  final List<({int column, String text})> monthLabels;
  final Color filledColor;
  final Color emptyColor;
  final Color disabledColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCells(canvas, size);
    _paintMonthLabels(canvas, size);
  }

  double _columnStart(Size size, int column) =>
      isRtl ? size.width - (column + 1) * cellSize : column * cellSize;

  void _paintCells(Canvas canvas, Size size) {
    final inset = math.max(0.75, cellSize * 0.06);
    final radius = Radius.circular(cellSize / 4);
    final filledPaint = Paint()..color = filledColor;
    final emptyPaint = Paint()..color = emptyColor;
    final disabledPaint = Paint()..color = disabledColor;
    Paint paintOf(int dayIndex) {
      if (!layout.isInRange(dayIndex)) return disabledPaint;
      return filledDays.contains(layout.dates[dayIndex])
          ? filledPaint
          : emptyPaint;
    }

    for (var column = 0; column < layout.weekCount; column++) {
      for (var row = 0; row < DateTime.daysPerWeek; row++) {
        final rect = Rect.fromLTWH(
          _columnStart(size, column) + inset,
          monthLabelHeight + row * cellSize + inset,
          cellSize - 2 * inset,
          cellSize - 2 * inset,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius),
          paintOf(layout.dayIndexOf(column, row)),
        );
      }
    }
  }

  void _paintMonthLabels(Canvas canvas, Size size) {
    final painters = [
      for (final label in monthLabels)
        (
          column: label.column,
          painter: TextPainter(
            text: TextSpan(text: label.text, style: labelStyle),
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          )..layout(),
        ),
    ];
    var nextLabelStart = double.infinity;
    for (final label in painters.reversed) {
      final labelStart = math.max(
        0.0,
        math.min(label.column * cellSize, size.width - label.painter.width),
      );
      if (labelStart + label.painter.width + 2 > nextLabelStart) continue;
      nextLabelStart = labelStart;
      final x =
          isRtl ? size.width - labelStart - label.painter.width : labelStart;
      label.painter.paint(canvas, Offset(x, 0));
    }
  }

  @override
  bool shouldRepaint(_DayCalendarPainter oldPainter) =>
      oldPainter.layout.start != layout.start ||
      oldPainter.layout.firstWeekday != layout.firstWeekday ||
      oldPainter.layout.dayCount != layout.dayCount ||
      oldPainter.layout.weekCount != layout.weekCount ||
      oldPainter.filledDays != filledDays ||
      oldPainter.cellSize != cellSize ||
      oldPainter.isRtl != isRtl ||
      oldPainter.monthLabels != monthLabels ||
      oldPainter.filledColor != filledColor ||
      oldPainter.emptyColor != emptyColor ||
      oldPainter.disabledColor != disabledColor ||
      oldPainter.labelStyle != labelStyle;
}
