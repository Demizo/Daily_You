import 'package:daily_you/models/entry.dart';

enum StatsRange { month, sixMonths, year, allTime }

List<Entry> entriesInRange(List<Entry> entries, StatsRange range,
    {DateTime? now}) {
  final monthCount = switch (range) {
    StatsRange.month => 1,
    StatsRange.sixMonths => 6,
    StatsRange.year => 12,
    StatsRange.allTime => 0,
  };
  if (monthCount == 0) return entries.toList();

  final today = now ?? DateTime.now();
  final start = DateTime(today.year, today.month - monthCount, today.day);
  return entries.where((entry) => entry.timeCreate.isAfter(start)).toList();
}
