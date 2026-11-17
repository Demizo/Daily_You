// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/models/mood_scale_level.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/widgets/mood_scale_glyph.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class _ClusterBubble {
  const _ClusterBubble(this.level, this.x, this.y, this.diameter);

  final int level;
  final double x;
  final double y;
  final double diameter;
}

class WelcomeIllustration extends StatelessWidget {
  static const double _aspectRatio = 1.7;
  static const double _logoWidth = 0.4;
  static const _bubbles = [
    _ClusterBubble(3, 0.15, 0.66, 0.28),
    _ClusterBubble(1, 0.22, 0.28, 0.18),
    _ClusterBubble(2, 0.68, 0.9, 0.13),
    _ClusterBubble(4, 0.85, 0.66, 0.28),
    _ClusterBubble(0, 0.78, 0.28, 0.18),
  ];

  const WelcomeIllustration({
    super.key,
    required this.ambient,
    required this.levels,
  });

  final Animation<double> ambient;
  final List<MoodScaleLevel> levels;

  MoodScaleLevel _bubbleLevel(int index) {
    final icon = MoodScalePreset.icons.levels[index];
    final userColor = index < levels.length ? levels[index].color : null;
    return userColor == null ? icon : icon.copyWith(color: userColor);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            alignment: Alignment.center,
            children: [
              const _IllustrationHalo(),
              ExcludeSemantics(
                child: SvgPicture.asset(
                  'assets/logo_mark.svg',
                  width: width * _logoWidth,
                  fit: BoxFit.contain,
                  colorFilter:
                      ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
                ),
              ),
              for (final (index, bubble) in _bubbles.indexed)
                Positioned(
                  left: bubble.x * width - bubble.diameter * height / 2,
                  top: bubble.y * height - bubble.diameter * height / 2,
                  child: _FloatingMood(
                    ambient: ambient,
                    index: index,
                    travel: height * 0.03,
                    child: RepaintBoundary(
                      child: _MoodBubble(
                        level: _bubbleLevel(bubble.level),
                        size: bubble.diameter * height,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _FloatingMood extends StatelessWidget {
  const _FloatingMood({
    required this.ambient,
    required this.index,
    required this.travel,
    required this.child,
  });

  final Animation<double> ambient;
  final int index;
  final double travel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        transform: Matrix4.translationValues(
          0,
          travel * math.sin(2 * math.pi * (ambient.value + index * 0.2)),
          0,
        )..rotateZ(
            0.12 * math.sin(2 * math.pi * (ambient.value * 2 + index * 0.3))),
        child: child,
      ),
      child: child,
    );
  }
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble({required this.level, required this.size});

  final MoodScaleLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Center(
        child: MoodScaleGlyph(
          level: level,
          size: size * 0.55,
          allowScaling: false,
        ),
      ),
    );
  }
}

class _IllustrationHalo extends StatelessWidget {
  static const double _scale = 0.86;

  const _IllustrationHalo();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: _scale,
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _BadgeCutoutClipper extends CustomClipper<Path> {
  const _BadgeCutoutClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldReclip(_BadgeCutoutClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

class OnboardingIllustration extends StatelessWidget {
  static const double _iconScale = 0.55;
  static const double _badgeScale = 0.42;
  static const double _badgeRingScale = 0.1;
  static const Offset _badgeCenter = Offset(0.86, 0.78);

  const OnboardingIllustration({
    super.key,
    required this.icon,
    this.badgeIcon,
  });

  final IconData icon;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(builder: (context, constraints) {
          final iconSize = constraints.maxHeight * _iconScale;
          final badgeSize = iconSize * _badgeScale;
          final badgeRing = badgeSize * _badgeRingScale;
          final badgeExtent = badgeSize + 2 * badgeRing;
          return Stack(
            alignment: Alignment.center,
            children: [
              const _IllustrationHalo(),
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: iconSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipPath(
                        clipper: badgeIcon == null
                            ? null
                            : _BadgeCutoutClipper(
                                center: Offset(
                                  iconSize * _badgeCenter.dx,
                                  iconSize * _badgeCenter.dy,
                                ),
                                radius: badgeExtent / 2,
                              ),
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (badgeIcon != null)
                        Positioned(
                          left: iconSize * _badgeCenter.dx - badgeExtent / 2,
                          top: iconSize * _badgeCenter.dy - badgeExtent / 2,
                          child: Padding(
                            padding: EdgeInsets.all(badgeRing),
                            child: Icon(
                              badgeIcon,
                              size: badgeSize,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
