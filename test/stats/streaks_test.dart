import 'package:daily_you/models/entry.dart';
import 'package:daily_you/stats/streaks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  Entry entryAt(DateTime time, {int? mood}) =>
      Entry(text: '', mood: mood, timeCreate: time, timeModified: time);

  test('reports nothing for an empty journal', () {
    final streaks = calculateStreaks([]);

    expect(streaks.current, 0);
    expect(streaks.longest, 0);
    expect(streaks.daysSinceBadDay, isNull);
  });

  test('counts a streak across a daylight saving transition', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 3, 10, 12)),
        entryAt(DateTime(2025, 3, 9, 12)),
        entryAt(DateTime(2025, 3, 8, 12)),
      ],
      now: DateTime(2025, 3, 10, 20),
    );

    expect(streaks.current, 3);
    expect(streaks.longest, 3);
  });

  test('counts adjacent calendar days written an hour apart', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 3, 9, 0, 30)),
        entryAt(DateTime(2025, 3, 8, 23, 30)),
      ],
      now: DateTime(2025, 3, 9, 8),
    );

    expect(streaks.current, 2);
    expect(streaks.longest, 2);
  });

  test('counts a day with several entries once', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 6, 2, 22)),
        entryAt(DateTime(2025, 6, 2, 13)),
        entryAt(DateTime(2025, 6, 2, 8)),
        entryAt(DateTime(2025, 6, 1, 9)),
      ],
      now: DateTime(2025, 6, 2, 23),
    );

    expect(streaks.current, 2);
    expect(streaks.longest, 2);
  });

  test('keeps the streak current when the last entry was yesterday', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 6, 1, 20)),
        entryAt(DateTime(2025, 5, 31, 20)),
      ],
      now: DateTime(2025, 6, 2, 9),
    );

    expect(streaks.current, 2);
    expect(streaks.longest, 2);
  });

  test('drops the streak when the last entry was two days ago', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 5, 31, 20)),
        entryAt(DateTime(2025, 5, 30, 20)),
      ],
      now: DateTime(2025, 6, 2, 9),
    );

    expect(streaks.current, 0);
    expect(streaks.longest, 2);
  });

  test('reports the longest past streak after a gap', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 6, 2)),
        entryAt(DateTime(2025, 5, 20)),
        entryAt(DateTime(2025, 5, 19)),
        entryAt(DateTime(2025, 5, 18)),
      ],
      now: DateTime(2025, 6, 2, 12),
    );

    expect(streaks.current, 1);
    expect(streaks.longest, 3);
  });

  test('counts a streak across a jalali month boundary', () {
    final nowruz = Jalali(1404, 1, 1).toDateTime();
    final lastDayOfEsfand = nowruz.subtract(const Duration(days: 1));
    expect(Jalali.fromDateTime(lastDayOfEsfand).month, 12);

    final streaks = calculateStreaks(
      [entryAt(nowruz), entryAt(lastDayOfEsfand)],
      now: nowruz,
    );

    expect(streaks.current, 2);
    expect(streaks.longest, 2);
  });

  test('measures the days since the most recent bad day', () {
    final streaks = calculateStreaks(
      [
        entryAt(DateTime(2025, 6, 2), mood: 2),
        entryAt(DateTime(2025, 5, 30), mood: -1),
        entryAt(DateTime(2025, 5, 20), mood: -2),
      ],
      now: DateTime(2025, 6, 2, 18),
    );

    expect(streaks.daysSinceBadDay, 3);
  });
}
