import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A data class representing a single item in the Expressive FAB Menu.
class ExpressiveFabMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ExpressiveFabMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// A Material 3 Expressive expanding Floating Action Button menu.
class ExpressiveFabMenu extends StatefulWidget {
  final List<ExpressiveFabMenuItem> items;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ExpressiveFabMenu({
    super.key,
    required this.items,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<ExpressiveFabMenu> createState() => _ExpressiveFabMenuState();
}

class _ExpressiveFabMenuState extends State<ExpressiveFabMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _overshootAnimation;
  late Animation<double> _undershootAnimation;
  late Animation<double> _radiusAnimation;

  late List<Animation<double>> _itemScaleAnimations;
  late List<Animation<double>> _itemFadeAnimations;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _overshootAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _undershootAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.1, curve: Curves.easeOutQuad),
      reverseCurve: const Interval(0.0, 0.1, curve: Curves.easeOutBack),
    );

    _radiusAnimation =
        Tween<double>(begin: 16.0, end: 28.0).animate(_undershootAnimation);

    _setupItemAnimations();
  }

  @override
  void didUpdateWidget(ExpressiveFabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _setupItemAnimations();
    }
  }

  void _setupItemAnimations() {
    _itemScaleAnimations = List.generate(widget.items.length, (index) {
      final itemIndex = widget.items.length - 1 - index;
      final start = (itemIndex * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.6).clamp(0.0, 1.0);

      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutBack), // Overshoots
        reverseCurve: Interval(start, end, curve: Curves.easeIn),
      );
    });

    _itemFadeAnimations = List.generate(widget.items.length, (index) {
      final itemIndex = widget.items.length - 1 - index;
      final start = (itemIndex * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.6).clamp(0.0, 1.0);

      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutQuad), // Strict bounds
        reverseCurve: Interval(start, end, curve: Curves.easeIn),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final scaleAnimation = _itemScaleAnimations[index];
          final fadeAnimation = _itemFadeAnimations[index];

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (scaleAnimation.value == 0.0) {
                return const SizedBox.shrink();
              }

              return Transform(
                // Diagonal3Values ensures strict horizontal (X-axis) expansion without vertical scaling
                transform:
                    Matrix4.diagonal3Values(scaleAnimation.value, 1.0, 1.0),
                alignment: AlignmentDirectional.centerEnd,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: colorScheme.primaryContainer,
              shape: const StadiumBorder(),
              elevation: 2,
              shadowColor: theme.shadowColor.withValues(alpha: 0.4),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _toggle();
                  item.onTap();
                },
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        _buildFab(colorScheme),
      ],
    );
  }

  Widget _buildFab(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: widget.backgroundColor ?? colorScheme.primary,
          borderRadius: BorderRadius.circular(_radiusAnimation.value),
          elevation: _isOpen ? 4 : 2,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _toggle,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _overshootAnimation.value * math.pi / 4,
                    child: Transform.scale(
                      scale: 1.0 - (_overshootAnimation.value * 0.5),
                      child: Icon(
                        Icons.add,
                        size: 26,
                        color: widget.foregroundColor ?? colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: -(1.0 - _overshootAnimation.value) * math.pi / 4,
                    child: Transform.scale(
                      scale: 0.5 + (_overshootAnimation.value * 0.5),
                      child: Icon(
                        Icons.close,
                        size: 26,
                        color: widget.foregroundColor ?? colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
