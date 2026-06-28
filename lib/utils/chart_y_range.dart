import 'dart:math' as math;

/// The rendered Y axis bounds plus spacing.
typedef ChartRange = ({double minY, double maxY, double? interval});

sealed class ChartYRange {
  const ChartYRange();

  /// Range shown for preview data
  ChartRange get previewRange;

  /// Range used for real values
  ChartRange resolve(Iterable<double> values);
}

/// A fixed range with caller-supplied bounds.
final class FixedYRange extends ChartYRange {
  final double minY;
  final double maxY;
  final double? interval;

  const FixedYRange({
    required this.minY,
    required this.maxY,
    this.interval,
  });

  @override
  ChartRange get previewRange => (minY: minY, maxY: maxY, interval: interval);

  @override
  ChartRange resolve(Iterable<double> values) => previewRange;
}

/// A range that auto-scales from data, starting at 0.
final class DynamicYRange extends ChartYRange {
  const DynamicYRange();

  @override
  ChartRange get previewRange => (minY: 0, maxY: 5, interval: null);

  @override
  ChartRange resolve(Iterable<double> values) {
    final maxValue = values.fold<double>(0.0, math.max);
    if (maxValue <= 0) return (minY: 0, maxY: 1, interval: null);
    return (minY: 0, maxY: maxValue, interval: null);
  }
}
