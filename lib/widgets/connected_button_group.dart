import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

const double _kFullRadius = 50.0;
const double _kInnerRadius = 8.0;
const double _kHPad = 16.0;
const double _kVPad = 10.0;
const double _kMinButtonWidth = _kFullRadius + _kInnerRadius + 4.0;
const Duration _kAnimDuration = Duration(milliseconds: 300);

class _DynamicPillBorder extends ShapeBorder {
  final double leftRadius;
  final double rightRadius;

  const _DynamicPillBorder({
    required this.leftRadius,
    required this.rightRadius,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double maxR = rect.height / 2.0;
    final double actualLeft = leftRadius.clamp(0.0, maxR);
    final double actualRight = rightRadius.clamp(0.0, maxR);

    return Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(actualLeft),
          bottomLeft: Radius.circular(actualLeft),
          topRight: Radius.circular(actualRight),
          bottomRight: Radius.circular(actualRight),
        ),
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _DynamicPillBorder(
        leftRadius: leftRadius * t,
        rightRadius: rightRadius * t,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _DynamicPillBorder) {
      return _DynamicPillBorder(
        leftRadius: lerpDouble(a.leftRadius, leftRadius, t)!,
        rightRadius: lerpDouble(a.rightRadius, rightRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _DynamicPillBorder) {
      return _DynamicPillBorder(
        leftRadius: lerpDouble(leftRadius, b.leftRadius, t)!,
        rightRadius: lerpDouble(rightRadius, b.rightRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is _DynamicPillBorder &&
        other.leftRadius == leftRadius &&
        other.rightRadius == rightRadius;
  }

  @override
  int get hashCode => Object.hash(leftRadius, rightRadius);
}

ShapeBorder _computeBorder({
  required int index,
  required int count,
  required double selFrac,
}) {
  final bool isFirst = index == 0;
  final bool isLast = index == count - 1;
  final double clamped = selFrac.clamp(0.0, 1.0);

  final double leftR = isFirst
      ? _kFullRadius
      : lerpDouble(_kInnerRadius, _kFullRadius, clamped)!;
  final double rightR =
      isLast ? _kFullRadius : lerpDouble(_kInnerRadius, _kFullRadius, clamped)!;

  return _DynamicPillBorder(leftRadius: leftR, rightRadius: rightR);
}

class ConnectedButtonGroup extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  const ConnectedButtonGroup({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          labels.length,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: _ConnectedButton(
              label: labels[i],
              index: i,
              count: labels.length,
              selectedIndex: selectedIndex,
              onTap: () => onSelectionChanged(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectedButton extends StatelessWidget {
  final String label;
  final int index;
  final int count;
  final int selectedIndex;
  final VoidCallback onTap;

  const _ConnectedButton({
    required this.label,
    required this.index,
    required this.count,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isSelected = index == selectedIndex;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: _kAnimDuration,
      curve: Curves.easeOutBack,
      builder: (context, selFrac, _) {
        final shape = _computeBorder(
          index: index,
          count: count,
          selFrac: selFrac,
        );

        final Color bgColor = Color.lerp(
          cs.secondaryContainer,
          cs.primaryContainer,
          selFrac.clamp(0.0, 1.0),
        )!;

        final Color fgColor = Color.lerp(
          cs.onSecondaryContainer,
          cs.onPrimaryContainer,
          selFrac.clamp(0.0, 1.0),
        )!;

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _kMinButtonWidth),
          child: Material(
            animationDuration: Duration.zero,
            color: bgColor,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _kHPad,
                  vertical: _kVPad,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: fgColor),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
