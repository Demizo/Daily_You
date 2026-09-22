import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum AutoBackupInterval {
  daily('daily', Duration(hours: 24)),
  weekly('weekly', Duration(days: 7)),
  monthly('monthly', Duration(days: 30));

  const AutoBackupInterval(this.key, this.duration);

  final String key;

  /// Intervals use a fixed duration, not calendar units
  final Duration duration;

  static AutoBackupInterval fromKey(String? key) =>
      values.firstWhere((interval) => interval.key == key, orElse: () => daily);

  String label(BuildContext context) => switch (this) {
        AutoBackupInterval.daily =>
          AppLocalizations.of(context)!.settingsAutoBackupIntervalDaily,
        AutoBackupInterval.weekly =>
          AppLocalizations.of(context)!.settingsAutoBackupIntervalWeekly,
        AutoBackupInterval.monthly =>
          AppLocalizations.of(context)!.settingsAutoBackupIntervalMonthly,
      };

  DateTime advance(DateTime from) => from.add(duration);
}

/// The next time a backup is due. Now if none has ever run, or one
/// interval after the last run.
DateTime nextAutoBackupTime({
  required DateTime now,
  required DateTime? lastRun,
  required AutoBackupInterval interval,
}) {
  if (lastRun == null) return now;
  final due = interval.advance(lastRun);
  return due.isBefore(now) ? now : due;
}

/// Whether the schedule's due slot (one interval after [lastRun]) has
/// already passed without a backup recording a newer [lastRun].
bool autoBackupIsOverdue({
  required DateTime now,
  required DateTime? lastRun,
  required AutoBackupInterval interval,
}) {
  if (lastRun == null) return false;
  const gracePeriod = Duration(minutes: 2);
  return now.isAfter(interval.advance(lastRun).add(gracePeriod));
}

DateTime nextAutoBackupTimeFromConfig(ConfigProvider configProvider) =>
    nextAutoBackupTime(
      now: DateTime.now(),
      lastRun: DateTime.tryParse(configProvider.get(Settings.lastAutoBackup)),
      interval: AutoBackupInterval.fromKey(
          configProvider.get(Settings.autoBackupInterval)),
    );
