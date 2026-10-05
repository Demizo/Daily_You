// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class AudioWaveformDecoration extends StatefulWidget {
  const AudioWaveformDecoration({
    super.key,
    required this.seed,
    this.active = false,
    this.color,
    this.sideInset = 0,
  });

  static const double pageSideInset = 64;

  final int seed;
  final bool active;
  final Color? color;
  final double sideInset;

  @override
  State<AudioWaveformDecoration> createState() =>
      _AudioWaveformDecorationState();
}

class _AudioWaveformDecorationState extends State<AudioWaveformDecoration>
    with TickerProviderStateMixin {
  static const Duration _motionPeriod = Duration(milliseconds: 1800);
  static const Duration _settleDuration = Duration(milliseconds: 300);

  late final AnimationController _motion =
      AnimationController(vsync: this, duration: _motionPeriod);
  late final AnimationController _intensity =
      AnimationController(vsync: this, duration: _settleDuration);

  @override
  void initState() {
    super.initState();
    _intensity.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _motion.stop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(AudioWaveformDecoration oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_motion.isAnimating) _motion.repeat();
      _intensity.forward();
    } else {
      _intensity.reverse();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _intensity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WaveformPainter(
          seed: widget.seed,
          color: color,
          sideInset: widget.sideInset,
          motion: _motion,
          intensity: _intensity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.seed,
    required this.color,
    required this.sideInset,
    required this.motion,
    required this.intensity,
  }) : super(repaint: Listenable.merge([motion, intensity]));

  final int seed;
  final Color color;
  final double sideInset;
  final Animation<double> motion;
  final Animation<double> intensity;

  static const double _slotWidth = 10;
  static const int _taperBars = 9;
  static const double _maxHeightFraction = 0.6;
  static const int _motionSeedMix = 0x5bd1e995;
  static const double _lowestMotionScale = 0.4;
  static const double _highestMotionScale = 1.3;
  static const int _motionCycles = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final motionRandom = math.Random(seed ^ _motionSeedMix);
    final moving = intensity.value > 0;
    final paint = Paint()..color = color;
    final barCount = math.max(1, (size.width - 2 * sideInset) ~/ _slotWidth);
    final taperBars = math.min(_taperBars, barCount ~/ 2);
    final barWidth = _slotWidth * 0.6;
    final maxBarHeight = size.height * _maxHeightFraction;
    final startX = (size.width - barCount * _slotWidth) / 2;

    for (var i = 0; i < barCount; i++) {
      final edgeDistance = math.min(i, barCount - 1 - i);
      final taper = Curves.easeOut
          .transform(((edgeDistance + 1) / (taperBars + 1)).clamp(0.0, 1.0));
      final heightFraction = (0.2 + random.nextDouble() * 0.8) * taper;

      final scale = moving ? _motionScale(motionRandom) : 1.0;

      final barHeight =
          math.max(barWidth, maxBarHeight * heightFraction * scale);
      final left = startX + i * _slotWidth + (_slotWidth - barWidth) / 2;
      final top = (size.height - barHeight) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  double _motionScale(math.Random motionRandom) {
    final cycles = 1 + motionRandom.nextInt(_motionCycles);
    final offset = motionRandom.nextDouble();
    final wave =
        0.5 + 0.5 * math.sin(2 * math.pi * (motion.value * cycles + offset));
    final motionScale =
        _lowestMotionScale + (_highestMotionScale - _lowestMotionScale) * wave;
    return 1 + (motionScale - 1) * intensity.value;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.color != color ||
      oldDelegate.sideInset != sideInset;
}
