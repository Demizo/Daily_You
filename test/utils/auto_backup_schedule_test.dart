import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime nextRun({
    required DateTime now,
    DateTime? lastRun,
    AutoBackupInterval interval = AutoBackupInterval.daily,
  }) =>
      nextAutoBackupTime(now: now, lastRun: lastRun, interval: interval);

  group('with no previous run', () {
    test('is due right now', () {
      final now = DateTime(2026, 5, 18, 9, 0);
      expect(nextRun(now: now), now);
    });
  });

  group('with a previous run', () {
    test('waits a full week between weekly backups', () {
      expect(
          nextRun(
              now: DateTime(2026, 5, 18, 9, 0),
              lastRun: DateTime(2026, 5, 18, 2, 0),
              interval: AutoBackupInterval.weekly),
          DateTime(2026, 5, 25, 2, 0));
    });

    test('does not slip when the app is opened between backups', () {
      final lastRun = DateTime(2026, 5, 18, 2, 0);
      final due = DateTime(2026, 5, 25, 2, 0);

      for (final now in [
        DateTime(2026, 5, 19, 9, 0),
        DateTime(2026, 5, 21, 20, 0),
        DateTime(2026, 5, 24, 23, 59),
      ]) {
        expect(
            nextRun(
                now: now,
                lastRun: lastRun,
                interval: AutoBackupInterval.weekly),
            due);
      }
    });

    test('advances by a fixed 30 days for monthly, not a calendar month', () {
      expect(
          nextRun(
              now: DateTime(2026, 5, 20, 9, 0),
              lastRun: DateTime(2026, 5, 18, 2, 0),
              interval: AutoBackupInterval.monthly),
          DateTime(2026, 6, 17, 2, 0));
    });

    test('is due immediately once the interval has already passed', () {
      final now = DateTime(2026, 6, 30, 9, 0);
      expect(
          nextRun(
              now: now,
              lastRun: DateTime(2026, 5, 18, 2, 0),
              interval: AutoBackupInterval.monthly),
          now);
    });
  });

  group('interval durations', () {
    test('map to the fixed durations WorkManager schedules against', () {
      expect(AutoBackupInterval.daily.duration, const Duration(hours: 24));
      expect(AutoBackupInterval.weekly.duration, const Duration(days: 7));
      expect(AutoBackupInterval.monthly.duration, const Duration(days: 30));
    });
  });

  group('interval keys', () {
    test('round trip through config values', () {
      for (final interval in AutoBackupInterval.values) {
        expect(AutoBackupInterval.fromKey(interval.key), interval);
      }
    });

    test('fall back to daily when unset or unknown', () {
      expect(AutoBackupInterval.fromKey(null), AutoBackupInterval.daily);
      expect(AutoBackupInterval.fromKey(''), AutoBackupInterval.daily);
      expect(AutoBackupInterval.fromKey('yearly'), AutoBackupInterval.daily);
    });
  });

  group('autoBackupIsOverdue', () {
    bool overdue({
      required DateTime now,
      DateTime? lastRun,
      AutoBackupInterval interval = AutoBackupInterval.daily,
    }) =>
        autoBackupIsOverdue(now: now, lastRun: lastRun, interval: interval);

    test('is not overdue when it has never run', () {
      expect(overdue(now: DateTime(2026, 5, 19, 9, 0)), isFalse);
    });

    test('is not overdue while the due slot is still ahead', () {
      expect(
          overdue(
              now: DateTime(2026, 5, 17, 20, 0),
              lastRun: DateTime(2026, 5, 17, 2, 0)),
          isFalse);
    });

    test('is not overdue within the grace period right after the slot', () {
      expect(
          overdue(
              now: DateTime(2026, 5, 18, 2, 1),
              lastRun: DateTime(2026, 5, 17, 2, 0)),
          isFalse);
    });

    test('is overdue once the due slot has clearly passed', () {
      expect(
          overdue(
              now: DateTime(2026, 5, 18, 9, 0),
              lastRun: DateTime(2026, 5, 17, 2, 0)),
          isTrue);
    });

    test('is overdue for a missed weekly backup', () {
      expect(
          overdue(
              now: DateTime(2026, 5, 26, 9, 0),
              lastRun: DateTime(2026, 5, 18, 2, 0),
              interval: AutoBackupInterval.weekly),
          isTrue);
    });
  });
}
