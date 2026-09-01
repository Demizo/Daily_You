import 'package:flutter/widgets.dart';

typedef ToolbarEntryBuilder = Widget Function(
    BuildContext context, VoidCallback? dismissOverflow);

enum ToolbarEntryKind { action, divider, spacer }

@immutable
class ToolbarEntry {
  final double width;
  final ToolbarEntryKind kind;

  final String? group;

  final ToolbarEntryBuilder build;

  const ToolbarEntry({
    required this.width,
    this.kind = ToolbarEntryKind.action,
    this.group,
    required this.build,
  });

  bool get isFiller => kind != ToolbarEntryKind.action;
}

@immutable
class ToolbarEntrySplit {
  static const double _fitTolerance = 1.0;

  final List<ToolbarEntry> visible;
  final List<ToolbarEntry> overflow;
  final double pillWidth;

  const ToolbarEntrySplit._(this.visible, this.overflow, this.pillWidth);

  bool get hasOverflow => overflow.isNotEmpty;

  factory ToolbarEntrySplit.fit(
    List<ToolbarEntry> entries, {
    required double maxWidth,
    required double overflowButtonWidth,
    required double padding,
  }) {
    double widthOf(Iterable<ToolbarEntry> range) =>
        range.fold(padding * 2, (sum, entry) => sum + entry.width);

    if (maxWidth <= 0 || widthOf(entries) <= maxWidth - _fitTolerance) {
      return ToolbarEntrySplit._(entries, const <ToolbarEntry>[],
          widthOf(entries).clamp(0.0, maxWidth));
    }

    var used = padding * 2 + overflowButtonWidth;
    var splitIndex = 0;
    while (splitIndex < entries.length &&
        used + entries[splitIndex].width <= maxWidth - _fitTolerance) {
      used += entries[splitIndex].width;
      splitIndex++;
    }
    splitIndex = _trimTrailingFiller(entries, splitIndex);

    final straddlingGroups = _groupsIn(entries.take(splitIndex))
        .intersection(_groupsIn(entries.skip(splitIndex)));
    if (straddlingGroups.isNotEmpty) {
      while (splitIndex > 0 &&
          straddlingGroups.contains(entries[splitIndex - 1].group)) {
        splitIndex--;
      }
      splitIndex = _trimTrailingFiller(entries, splitIndex);
    }

    var overflowStart = splitIndex;
    while (overflowStart < entries.length && entries[overflowStart].isFiller) {
      overflowStart++;
    }

    final visible = entries.sublist(0, splitIndex);
    return ToolbarEntrySplit._(
      visible,
      entries.sublist(overflowStart),
      (widthOf(visible) + overflowButtonWidth).clamp(0.0, maxWidth),
    );
  }

  static Set<String> _groupsIn(Iterable<ToolbarEntry> entries) =>
      entries.map((entry) => entry.group).nonNulls.toSet();

  static int _trimTrailingFiller(List<ToolbarEntry> entries, int splitIndex) {
    while (splitIndex > 0 && entries[splitIndex - 1].isFiller) {
      splitIndex--;
    }
    return splitIndex;
  }
}
