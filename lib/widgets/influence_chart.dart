// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/mood.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/stats/stats_influence.dart';
import 'package:daily_you/utils/mood_scale_visuals.dart';
import 'package:daily_you/utils/secondary_text_style.dart';
import 'package:daily_you/utils/tag_visuals.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class InfluenceChart extends StatelessWidget {
  const InfluenceChart({
    super.key,
    required this.influences,
    required this.title,
    required this.onTagSelected,
    this.minimum,
    this.maximum,
    this.showMoodBands = false,
    this.padAxis = true,
    this.scaleLabelBuilder,
  });

  static const double _rowHeight = 36;
  static const double _minimumLabelWidth = 96;
  static const double _maximumLabelWidth = 200;
  static const double _labelWidthFraction = 0.34;
  static const double _axisPaddingFraction = 0.3;
  static const double _scaleLabelWidth = 36;

  final List<TagInfluence> influences;
  final String title;
  final ValueChanged<Tag> onTagSelected;
  final double? minimum;
  final double? maximum;
  final bool showMoodBands;
  final bool padAxis;
  final Widget Function(double value)? scaleLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final moodScale = context.watch<MoodScaleProvider>();
    final rowHeight = MediaQuery.textScalerOf(context).scale(_rowHeight);
    final means = [
      for (final influence in influences) ...[
        influence.presentMean,
        influence.absentMean,
      ],
    ];
    final smallest = means.reduce(math.min);
    final largest = means.reduce(math.max);
    final padding = padAxis ? (largest - smallest) * _axisPaddingFraction : 0.0;
    final lowest = padAxis
        ? math.max(smallest - padding, minimum ?? double.negativeInfinity)
        : minimum ?? smallest;
    final highest = padAxis
        ? math.min(largest + padding, maximum ?? double.infinity)
        : maximum ?? largest;
    final span = highest - lowest;
    final bands = [
      if (showMoodBands)
        for (var position = 0; position < Mood.count; position++)
          (
            from: (position - 0.5 - lowest) / span,
            to: (position + 0.5 - lowest) / span,
            color: moodScale
                    .levelOf(Mood.fromPosition(position))
                    ?.resolvedColor(context) ??
                colorScheme.primary,
          ),
    ];

    return Card.filled(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: LayoutBuilder(builder: (context, constraints) {
              final labelWidth = (constraints.maxWidth * _labelWidthFraction)
                  .clamp(_minimumLabelWidth, _maximumLabelWidth);
              return Column(children: [
                for (final influence in influences)
                  InkWell(
                    borderRadius: BorderRadius.circular(rowHeight / 2),
                    onTap: () => onTagSelected(influence.tag),
                    child: SizedBox(
                      height: rowHeight,
                      child: Row(children: [
                        SizedBox(
                          width: labelWidth,
                          child: Row(children: [
                            TagIconGlyph(
                              icon: influence.tag.icon,
                              iconType: influence.tag.iconType,
                              fallbackIcon: influence.tag.typeIcon,
                              color: influence.tag.resolvedColor(context),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                influence.tag.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ),
                        if (scaleLabelBuilder case final buildScaleLabel?)
                          _ScaleLabel(child: buildScaleLabel(lowest)),
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _DumbbellPainter(
                              present: (influence.presentMean - lowest) / span,
                              absent: (influence.absentMean - lowest) / span,
                              color: influence.tag.resolvedColor(context),
                              track: colorScheme.surfaceContainerHighest,
                              plate: colorScheme.surfaceContainerLow,
                              bands: bands,
                              isRightToLeft: Directionality.of(context) ==
                                  TextDirection.rtl,
                            ),
                          ),
                        ),
                        if (scaleLabelBuilder case final buildScaleLabel?)
                          _ScaleLabel(child: buildScaleLabel(highest)),
                      ]),
                    ),
                  ),
                const _InfluenceLegend(),
              ]);
            }),
          ),
        ],
      ),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  const _DumbbellPainter({
    required this.present,
    required this.absent,
    required this.color,
    required this.track,
    required this.plate,
    required this.bands,
    required this.isRightToLeft,
  });

  static const double _trackHeight = 18;
  static const double _bandAlpha = 0.18;
  static const double _stemWidth = 4;
  static const double _presentRadius = 7;
  static const double _absentRadius = 6;
  static const double _absentStroke = 2.5;

  final double present;
  final double absent;
  final Color color;
  final Color track;
  final Color plate;
  final List<({double from, double to, Color color})> bands;
  final bool isRightToLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const markerInset = _trackHeight / 2;
    double xOf(double fraction, {double inset = markerInset}) {
      final clamped = fraction.clamp(0.0, 1.0);
      final along = isRightToLeft ? 1 - clamped : clamped;
      return inset + along * (size.width - 2 * inset);
    }

    double bandEdgeOf(double fraction) =>
        xOf(fraction, inset: fraction <= 0 || fraction >= 1 ? 0 : markerInset);

    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centerY - _trackHeight / 2, size.width, _trackHeight),
      Radius.circular(_trackHeight / 2),
    );
    canvas.save();
    canvas.clipRRect(trackRect);
    canvas.drawRRect(trackRect, Paint()..color = track);
    for (final band in bands) {
      final edges = [bandEdgeOf(band.from), bandEdgeOf(band.to)]..sort();
      canvas.drawRect(
        Rect.fromLTRB(edges.first, centerY - _trackHeight / 2, edges.last,
            centerY + _trackHeight / 2),
        Paint()..color = band.color.withValues(alpha: _bandAlpha),
      );
    }
    canvas.restore();

    final absentCenter = Offset(xOf(absent), centerY);
    final presentCenter = Offset(xOf(present), centerY);
    canvas.drawLine(
      absentCenter,
      presentCenter,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = _stemWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(absentCenter, _absentRadius, Paint()..color = plate);
    canvas.drawCircle(
      absentCenter,
      _absentRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _absentStroke,
    );
    canvas.drawCircle(presentCenter, _presentRadius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DumbbellPainter oldDelegate) =>
      oldDelegate.present != present ||
      oldDelegate.absent != absent ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.plate != plate ||
      oldDelegate.isRightToLeft != isRightToLeft ||
      oldDelegate.bands != bands;
}

class _InfluenceLegend extends StatelessWidget {
  const _InfluenceLegend();

  static const double _dotSize = 12;
  static const double _outlineWidth = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final textStyle = secondaryTextStyle(context, fontSize: 12);

    Widget entry(bool isFilled, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? color : null,
                border: isFilled
                    ? null
                    : Border.all(color: color, width: _outlineWidth),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: textStyle),
          ],
        );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 4,
        children: [
          entry(true, l10n.labelPresentLabel),
          entry(false, l10n.labelAbsentLabel),
        ],
      ),
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: InfluenceChart._scaleLabelWidth,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DefaultTextStyle.merge(
              style: secondaryTextStyle(context, fontSize: 12),
              child: child,
            ),
          ),
        ),
      );
}
