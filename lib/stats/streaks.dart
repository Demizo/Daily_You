import 'package:daily_you/models/entry.dart';

typedef Streaks = ({int current, int longest, int? daysSinceBadDay});

/// Calculate streaks. [entries] must be in reverse chronological order
Streaks calculateStreaks(List<Entry> entries, {DateTime? now}) {
  if (entries.isEmpty) return (current: 0, longest: 0, daysSinceBadDay: null);

  final today = _calendarDay(now ?? DateTime.now());
  final mostRecentDay = _calendarDay(entries.first.timeCreate);
  final isCurrent = today.difference(mostRecentDay).inDays <= 1;

  var current = 0;
  var longest = 0;
  int? daysSinceBadDay;

  var activeStreak = 0;
  var isFirstStreak = true;
  DateTime? previousDay;

  for (final entry in entries) {
    final day = _calendarDay(entry.timeCreate);

    if (daysSinceBadDay == null && entry.mood != null && entry.mood! < 0) {
      daysSinceBadDay = today.difference(day).inDays;
    }

    if (previousDay == null) {
      activeStreak = 1;
      longest = 1;
    } else if (previousDay != day) {
      final dayGap = previousDay.difference(day).inDays;
      if (dayGap == 1) {
        activeStreak += 1;
        if (activeStreak > longest) longest = activeStreak;
      } else if (dayGap > 1) {
        if (isFirstStreak) {
          if (isCurrent) current = activeStreak;
          isFirstStreak = false;
        }
        activeStreak = 1;
      }
    }

    previousDay = day;
  }

  if (isFirstStreak && isCurrent) current = activeStreak;

  return (current: current, longest: longest, daysSinceBadDay: daysSinceBadDay);
}

DateTime _calendarDay(DateTime dateTime) =>
    DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
