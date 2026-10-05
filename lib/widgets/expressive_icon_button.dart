// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class ExpressiveIconButton extends StatelessWidget {
  const ExpressiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = defaultSize,
    this.squared = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool squared;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static const double defaultSize = 64;
  static const double _squaredRadiusFraction = 20 / 64;
  static const double _iconSizeFraction = 36 / 64;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final disabledBackground = Color.alphaBlend(
        colors.onSurface.withValues(alpha: 0.12), colors.surface);
    final disabledForeground = Color.alphaBlend(
        colors.onSurface.withValues(alpha: 0.38), disabledBackground);
    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
              squared ? size * _squaredRadiusFraction : size / 2),
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          tween: ColorTween(
            end: enabled
                ? backgroundColor ?? colors.primary
                : disabledBackground,
          ),
          builder: (context, color, child) =>
              ColoredBox(color: color!, child: child),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: TweenAnimationBuilder<Color?>(
                    key: ValueKey(icon),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    tween: ColorTween(
                      end: enabled
                          ? foregroundColor ?? colors.onPrimary
                          : disabledForeground,
                    ),
                    builder: (context, color, _) => Icon(icon,
                        size: size * _iconSizeFraction, color: color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
