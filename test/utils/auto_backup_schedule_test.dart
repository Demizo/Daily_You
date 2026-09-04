import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const backupAt = TimeOfDay(hour: 2, minute: 0);

  DateTime nextRun({
    required DateTime now,
    DateTime? lastRun,
    AutoBackupInterval interval = AutoBackupInterval.daily,
    TimeOfDay timeOfDay = backupAt,
  }) =>
      nextAutoBackupTime(
          now: now, lastRun: lastRun, interval: interval, timeOfDay: timeOfDay);

  group('with no previous run', () {
    test('takes today\'s slot when it is still ahead', () {
      expect(nextRun(now: DateTime(2026, 5, 18, 1, 30)),
          DateTime(2026, 5, 18, 2, 0));
    });

    test('rolls to tomorrow once the slot has passed', () {
      expect(nextRun(now: DateTime(2026, 5, 18, 9, 0)),
          DateTime(2026, 5, 19, 2, 0));
    });

    test('rolls forward when the slot is exactly now', () {
      expect(nextRun(now: DateTime(2026, 5, 18, 2, 0)),
          DateTime(2026, 5, 19, 2, 0));
    });
  });

  group('with a previous run', () {
    test('waits a full week between weekly backups', () {
      expect(
          nextRun(
              now: DateTime(2026, 5, 18, 9, 0),
              lastRun: DateTime(2026, 5, 18, 2, 0, 30),
              interval: AutoBackupInterval.weekly),
          DateTime(2026, 5, 25, 2, 0));
    });

    test('does not slip when the app is opened between backups', () {
      final lastRun = DateTime(2026, 5, 18, 2, 0, 30);
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

    test('crosses into the next month', () {
      expect(
          nextRun(
              now: DateTime(2026, 5, 20, 9, 0),
              lastRun: DateTime(2026, 5, 18, 2, 0),
              interval: AutoBackupInterval.monthly),
          DateTime(2026, 6, 18, 2, 0));
    });

    test('catches up at the next slot when overdue', () {
      expect(
          nextRun(
              now: DateTime(2026, 6, 30, 9, 0),
              lastRun: DateTime(2026, 5, 18, 2, 0),
              interval: AutoBackupInterval.monthly),
          DateTime(2026, 7, 1, 2, 0));
    });

    test('holds the wall clock time across a daylight saving change', () {
      final next = nextRun(
          now: DateTime(2026, 3, 7, 9, 0),
          lastRun: DateTime(2026, 3, 7, 2, 0),
          interval: AutoBackupInterval.weekly);

      expect(next.hour, 2);
      expect(next, DateTime(2026, 3, 14, 2, 0));
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
}
