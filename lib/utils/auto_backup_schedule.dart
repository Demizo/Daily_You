import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

enum AutoBackupInterval {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const AutoBackupInterval(this.key);

  final String key;

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

  DateTime advance(DateTime from) => switch (this) {
        AutoBackupInterval.daily =>
          DateTime(from.year, from.month, from.day + 1, from.hour, from.minute),
        AutoBackupInterval.weekly =>
          DateTime(from.year, from.month, from.day + 7, from.hour, from.minute),
        AutoBackupInterval.monthly =>
          DateTime(from.year, from.month + 1, from.day, from.hour, from.minute),
      };
}

DateTime nextAutoBackupTime({
  required DateTime now,
  required DateTime? lastRun,
  required AutoBackupInterval interval,
  required TimeOfDay timeOfDay,
}) {
  final due = lastRun == null ? now : interval.advance(lastRun);
  final from = due.isBefore(now) ? now : due;

  final slot = DateTime(
      from.year, from.month, from.day, timeOfDay.hour, timeOfDay.minute);
  if (slot.isAfter(now)) return slot;
  return DateTime(
      from.year, from.month, from.day + 1, timeOfDay.hour, timeOfDay.minute);
}

DateTime nextAutoBackupTimeFromConfig(ConfigProvider configProvider) =>
    nextAutoBackupTime(
      now: DateTime.now(),
      lastRun: DateTime.tryParse(configProvider.get(Settings.lastAutoBackup)),
      interval: AutoBackupInterval.fromKey(
          configProvider.get(Settings.autoBackupInterval)),
      timeOfDay: TimeOfDay(
        hour: configProvider.get(Settings.autoBackupHour),
        minute: configProvider.get(Settings.autoBackupMinute),
      ),
    );
