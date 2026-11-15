// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:app_settings/app_settings.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/reminder_time_dialog.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  static TimeOfDay _onThisDayNotificationTime() {
    return TimeOfDay(
      hour: ConfigProvider.instance.get(Settings.onThisDayNotificationHour),
      minute: ConfigProvider.instance.get(Settings.onThisDayNotificationMinute),
    );
  }

  static Future<void> _selectOnThisDayTime(BuildContext context) async {
    final TimeOfDay? picked = await showAppTimePicker(
      context: context,
      initialTime: _onThisDayNotificationTime(),
    );

    if (picked != null) {
      await ConfigProvider.instance
          .set(Settings.onThisDayNotificationHour, picked.hour);
      await ConfigProvider.instance
          .set(Settings.onThisDayNotificationMinute, picked.minute);
      if (ConfigProvider.instance.get(Settings.onThisDayNotifications)) {
        await NotificationManager.instance.stopOnThisDayNotifications();
        await NotificationManager.instance.startOnThisDayNotifications();
      }
    }
  }

  static Future<void> selectReminderTime(BuildContext context) async {
    final selection = await showReminderTimePicker(context, initial: (
      fixed: ConfigProvider.instance.get(Settings.setReminderTime),
      time: TimeManager.scheduledReminderTime(),
      range: TimeManager.getReminderTimeRange(),
    ));
    if (selection == null) return;

    final configProvider = ConfigProvider.instance;
    await configProvider.set(Settings.setReminderTime, selection.fixed);
    await configProvider.set(
        Settings.scheduledReminderHour, selection.time.hour);
    await configProvider.set(
        Settings.scheduledReminderMinute, selection.time.minute);
    await TimeManager.setReminderTimeRange(selection.range);
    if (configProvider.get(Settings.dailyReminders)) {
      await NotificationManager.instance.stopDailyReminders();
      await NotificationManager.instance.startScheduledDailyReminders();
    }
  }

  static Future<void> _requestExactAlarms(BuildContext context) async {
    final notificationManager = NotificationManager.instance;
    if (await notificationManager.canScheduleExactAlarms() ||
        !context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final materialLocalizations = MaterialLocalizations.of(context);
    final shouldRequest = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsExactAlarmsTitle),
        content: Text(l10n.settingsExactAlarmsDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(materialLocalizations.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(materialLocalizations.continueButtonLabel),
          ),
        ],
      ),
    );
    if (shouldRequest ?? false) {
      await notificationManager.requestExactAlarmPermission();
    }
  }

  static Future<void> _setNotifications(
    BuildContext context,
    Setting<bool> setting,
    bool value, {
    required Future<void> Function() start,
    required Future<void> Function() stop,
  }) async {
    if (!await NotificationManager.instance.hasNotificationPermission()) return;
    if (value && context.mounted) await _requestExactAlarms(context);
    await (value ? start() : stop());
    await ConfigProvider.instance.set(setting, value);
  }

  static Future<void> setDailyReminders(BuildContext context, bool value) {
    return _setNotifications(
      context,
      Settings.dailyReminders,
      value,
      start: NotificationManager.instance.startScheduledDailyReminders,
      stop: NotificationManager.instance.stopDailyReminders,
    );
  }

  static Future<void> _setOnThisDay(BuildContext context, bool value) {
    return _setNotifications(
      context,
      Settings.onThisDayNotifications,
      value,
      start: NotificationManager.instance.startOnThisDayNotifications,
      stop: NotificationManager.instance.stopOnThisDayNotifications,
    );
  }

  static String dailyReminderTime(BuildContext context) {
    return ConfigProvider.instance.get(Settings.setReminderTime)
        ? TimeManager.timeOfDayString(
            context, TimeManager.scheduledReminderTime())
        : TimeManager.timeRangeString(
            context, TimeManager.getReminderTimeRange());
  }

  static List<Widget> buildCoreReminderSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOn = ConfigProvider.instance.get(Settings.dailyReminders);
    return [
      SettingsToggleRow(
          title: l10n.settingsDailyReminderTitle,
          subtitle: isOn
              ? dailyReminderTime(context)
              : l10n.settingsDailyReminderDescription,
          value: isOn,
          onChanged: (value) => setDailyReminders(context, value),
          onOpenOptions: () => selectReminderTime(context)),
    ];
  }

  static List<Widget> buildOnThisDaySettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOn = ConfigProvider.instance.get(Settings.onThisDayNotifications);
    return [
      SettingsToggleRow(
          title: l10n.flashbackOnThisDay,
          subtitle: isOn
              ? TimeManager.timeOfDayString(
                  context, _onThisDayNotificationTime())
              : l10n.settingsOnThisDayDescription,
          value: isOn,
          onChanged: (value) => _setOnThisDay(context, value),
          onOpenOptions: () => _selectOnThisDayTime(context)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);
    final dailyReminders = configProvider.get(Settings.dailyReminders);
    final onThisDay = configProvider.get(Settings.onThisDayNotifications);
    return SettingsPageScaffold(
      title: l10n.settingsNotificationsTitle,
      children: [
        SegmentedGroup(children: [
          ...buildCoreReminderSettings(context),
          SettingsDependents(
            enabled: dailyReminders,
            child: SettingsToggleRow.setting(
                title: l10n.settingsAlwaysSendReminderTitle,
                subtitle: l10n.settingsAlwaysSendReminderDescription,
                setting: Settings.alwaysRemind),
          ),
        ]),
        SegmentedGroup(children: buildOnThisDaySettings(context)),
        if (dailyReminders || onThisDay)
          SegmentedGroup(children: [
            SettingsActionRow(
                title: l10n.settingsCustomizeNotificationTitle,
                onTap: () => AppSettings.openAppSettings(
                    type: AppSettingsType.notification)),
          ]),
      ],
    );
  }
}
