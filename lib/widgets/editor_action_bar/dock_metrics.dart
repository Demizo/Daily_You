import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Publishes the keyboard-dock animation to everything below the overlay.
class DockProgressScope extends InheritedNotifier<Animation<double>> {
  const DockProgressScope({
    super.key,
    required Animation<double> progress,
    required super.child,
  }) : super(notifier: progress);

  /// 0 while floating, 1 while docked
  static double of(BuildContext context) {
    final progress = context
        .dependOnInheritedWidgetOfExactType<DockProgressScope>()
        ?.notifier;
    if (progress != null) return progress.value;

    const saturationInset = 32.0;
    return (MediaQuery.viewInsetsOf(context).bottom / saturationInset)
        .clamp(0.0, 1.0);
  }
}

@immutable
class DockMetrics {
  static const double screenMargin = 16.0;
  static const double toggleGap = 8.0;
  static const double itemSpacing = 4.0;

  static const double _floatingButtonSize = 48.0;
  static const double _dockedButtonSize = 40.0;
  static const double _floatingPillPadding = 8.0;
  static const double _dockedPillPadding = 4.0;
  static const double _dockedTopMargin = 8.0;
  static const double _floatingToggleSize = 56.0;
  static const double _dockedToggleSize = 40.0;
  static const double _floatingHeight =
      _floatingButtonSize + _floatingPillPadding * 2;

  static const double _elevationEaseBand = 0.3;
  static const double _floatingElevation = 3.0;

  final double progress;
  final double buttonSize;
  final double pillPadding;
  final double toggleSize;
  final double sideMargin;
  final double topMargin;

  final double contentInset;

  final double cornerRadius;
  final double pillElevation;

  const DockMetrics._({
    required this.progress,
    required this.buttonSize,
    required this.pillPadding,
    required this.toggleSize,
    required this.sideMargin,
    required this.topMargin,
    required this.contentInset,
    required this.cornerRadius,
    required this.pillElevation,
  });

  factory DockMetrics.at(double progress) {
    double lerp(double floating, double docked) =>
        lerpDouble(floating, docked, progress)!;

    return DockMetrics._(
      progress: progress,
      buttonSize: lerp(_floatingButtonSize, _dockedButtonSize),
      pillPadding: lerp(_floatingPillPadding, _dockedPillPadding),
      toggleSize: lerp(_floatingToggleSize, _dockedToggleSize),
      sideMargin: lerp(screenMargin, 0.0),
      topMargin: lerp(screenMargin, _dockedTopMargin),
      contentInset: lerp(0.0, _dockedPillPadding),
      cornerRadius: lerp(_floatingHeight / 2, 0.0),
      pillElevation: lerpDouble(_floatingElevation, 0.0,
          (progress / _elevationEaseBand).clamp(0.0, 1.0))!,
    );
  }

  static DockMetrics of(BuildContext context) =>
      DockMetrics.at(DockProgressScope.of(context));

  double get barHeight => buttonSize + pillPadding * 2;

  BorderRadius get borderRadius => BorderRadius.circular(cornerRadius);

  static double reservedHeight(BuildContext context) {
    final metrics = DockMetrics.of(context);
    return metrics.barHeight +
        metrics.topMargin +
        MediaQuery.paddingOf(context).bottom;
  }
}
