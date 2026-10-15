// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

typedef TimeRangeSelection = ({TimeOfDay start, TimeOfDay end});

Future<TimeRangeSelection?> showTimeRangePicker(
  BuildContext context, {
  required TimeRangeSelection initialRange,
}) {
  return showAppDialog<TimeRangeSelection>(
    context: context,
    builder: (context) => TimeRangePickerDialog(initialRange: initialRange),
  );
}

class TimeRangePickerDialog extends StatefulWidget {
  final TimeRangeSelection initialRange;

  const TimeRangePickerDialog({super.key, required this.initialRange});

  @override
  State<TimeRangePickerDialog> createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<TimeRangePickerDialog> {
  late int _start = _minutesOf(widget.initialRange.start);
  late int _end = _minutesOf(widget.initialRange.end);

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.settingsReminderTime),
      scrollable: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _TimeRangeDial(
            start: _start,
            end: _end,
            onChanged: (start, end) => setState(() {
              _start = start;
              _end = end;
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop((start: _timeOf(_start), end: _timeOf(_end))),
          child: Text(localizations.okButtonLabel),
        ),
      ],
    );
  }
}

const int _minutesPerDay = 24 * 60;

int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

TimeOfDay _timeOf(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

double _angleOf(double minutes) =>
    minutes / _minutesPerDay * 2 * math.pi - math.pi / 2;

const int _snapMinutes = 10;
const double _dialSize = 260;
const double _trackWidth = 16;
const double _ringInset = 28;
const double _handleSize = 32;
const double _handleHitRadius = 28;

enum _DragTarget { start, end, range }

const Offset _dialCenter = Offset(_dialSize / 2, _dialSize / 2);
const double _ringRadius = _dialSize / 2 - _ringInset;

Offset _directionAt(int minutes) {
  final angle = _angleOf(minutes.toDouble());
  return Offset(math.cos(angle), math.sin(angle));
}

Offset _pointAt(int minutes) =>
    _dialCenter + _directionAt(minutes) * _ringRadius;

double _minutesAt(Offset position) {
  final offset = position - _dialCenter;
  var angle = math.atan2(offset.dy, offset.dx) + math.pi / 2;
  if (angle < 0) angle += 2 * math.pi;
  return angle / (2 * math.pi) * _minutesPerDay;
}

class _TimeRangeDial extends StatefulWidget {
  final int start;
  final int end;
  final void Function(int start, int end) onChanged;

  const _TimeRangeDial({
    required this.start,
    required this.end,
    required this.onChanged,
  });

  @override
  State<_TimeRangeDial> createState() => _TimeRangeDialState();
}

class _TimeRangeDialState extends State<_TimeRangeDial> {
  _DragTarget? _dragTarget;
  double _anchorMinutes = 0;
  int _anchorStart = 0;
  int _anchorLength = 0;

  static int _snap(double minutes) =>
      ((minutes / _snapMinutes).round() * _snapMinutes) % _minutesPerDay;

  static int _wrap(int minutes) => minutes % _minutesPerDay;

  bool _rangeContains(double minutes) =>
      (minutes - widget.start) % _minutesPerDay <=
      _wrap(widget.end - widget.start);

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    final startDistance = (position - _pointAt(widget.start)).distance;
    final endDistance = (position - _pointAt(widget.end)).distance;
    final onTrack = ((position - _dialCenter).distance - _ringRadius).abs() <=
        _handleHitRadius;

    if (math.min(startDistance, endDistance) <= _handleHitRadius) {
      _dragTarget =
          startDistance <= endDistance ? _DragTarget.start : _DragTarget.end;
    } else if (onTrack && _rangeContains(_minutesAt(position))) {
      _dragTarget = _DragTarget.range;
      _anchorMinutes = _minutesAt(position);
      _anchorStart = widget.start;
      _anchorLength = _wrap(widget.end - widget.start);
    } else {
      _dragTarget = null;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final minutes = _minutesAt(details.localPosition);
    switch (_dragTarget) {
      case _DragTarget.start:
        widget.onChanged(_snap(minutes), widget.end);
      case _DragTarget.end:
        widget.onChanged(widget.start, _snap(minutes));
      case _DragTarget.range:
        var shift = minutes - _anchorMinutes;
        if (shift > _minutesPerDay / 2) shift -= _minutesPerDay;
        if (shift < -_minutesPerDay / 2) shift += _minutesPerDay;
        final start = _snap(_anchorStart + shift);
        widget.onChanged(start, _wrap(start + _anchorLength));
      case null:
        break;
    }
  }

  void _nudge(_DragTarget target, int minutes) {
    final start = target == _DragTarget.start
        ? _wrap(widget.start + minutes)
        : widget.start;
    final end =
        target == _DragTarget.end ? _wrap(widget.end + minutes) : widget.end;
    widget.onChanged(start, end);
  }

  String _timeText(int minutes) =>
      TimeManager.timeOfDayString(context, _timeOf(_wrap(minutes)));

  Widget _handle(_DragTarget target, int minutes) {
    final colorScheme = Theme.of(context).colorScheme;
    final point = _pointAt(minutes);
    return Positioned(
      left: point.dx - _handleSize / 2,
      top: point.dy - _handleSize / 2,
      child: Semantics(
        value: _timeText(minutes),
        increasedValue: _timeText(minutes + _snapMinutes),
        decreasedValue: _timeText(minutes - _snapMinutes),
        onIncrease: () => _nudge(target, _snapMinutes),
        onDecrease: () => _nudge(target, -_snapMinutes),
        child: Container(
          key: ValueKey('time-range-${target.name}'),
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.surface, width: 3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = TimeManager.currentLocale(context);
    final timeStyle = Theme.of(context).textTheme.titleMedium;
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      child: SizedBox.square(
        dimension: _dialSize,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size.square(_dialSize),
              painter: _DialPainter(
                start: widget.start,
                end: widget.end,
                trackColor: colorScheme.surfaceContainerHighest,
                rangeColor: colorScheme.primary,
                tickColor: colorScheme.outlineVariant,
                labelStyle: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(color: colorScheme.onSurfaceVariant),
                labels: [
                  for (final hour in [0, 6, 12, 18])
                    (
                      hour * 60,
                      DateFormat.j(locale).format(DateTime(2000, 1, 1, hour)),
                    ),
                ],
                textDirection: Directionality.of(context),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_timeText(widget.start), style: timeStyle),
                  Text('–', style: timeStyle),
                  Text(_timeText(widget.end), style: timeStyle),
                ],
              ),
            ),
            _handle(_DragTarget.start, widget.start),
            _handle(_DragTarget.end, widget.end),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final int start;
  final int end;
  final Color trackColor;
  final Color rangeColor;
  final Color tickColor;
  final TextStyle labelStyle;
  final List<(int, String)> labels;
  final TextDirection textDirection;

  const _DialPainter({
    required this.start,
    required this.end,
    required this.trackColor,
    required this.rangeColor,
    required this.tickColor,
    required this.labelStyle,
    required this.labels,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const center = _dialCenter;
    const radius = _ringRadius;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _trackWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint..color = trackColor);

    final sweep =
        ((end - start) % _minutesPerDay) / _minutesPerDay * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _angleOf(start.toDouble()),
      sweep,
      false,
      trackPaint..color = rangeColor,
    );

    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final tickRadius = radius - _trackWidth / 2 - 6;
    for (var hour = 0; hour < 24; hour++) {
      final direction = _directionAt(hour * 60);
      canvas.drawLine(center + direction * tickRadius,
          center + direction * (tickRadius - 4), tickPaint);
    }

    final labelRadius = tickRadius - 22;
    for (final (minutes, text) in labels) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: textDirection,
      )..layout();
      painter.paint(
        canvas,
        center +
            _directionAt(minutes) * labelRadius -
            Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      start != oldDelegate.start ||
      end != oldDelegate.end ||
      trackColor != oldDelegate.trackColor ||
      rangeColor != oldDelegate.rangeColor ||
      tickColor != oldDelegate.tickColor ||
      labelStyle != oldDelegate.labelStyle ||
      textDirection != oldDelegate.textDirection ||
      !listEquals(labels, oldDelegate.labels);
}
