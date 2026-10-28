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
import 'package:daily_you/widgets/time_range_picker_dialog.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  static Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeManager.scheduledReminderTime(),
      builder: (context, child) => AppDialogTransition(child: child!),
    );

    if (picked != null) {
      await ConfigProvider.instance
          .set(Settings.scheduledReminderHour, picked.hour);
      await ConfigProvider.instance
          .set(Settings.scheduledReminderMinute, picked.minute);
      if (ConfigProvider.instance.get(Settings.dailyReminders)) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
    }
  }

  static TimeOfDay _onThisDayNotificationTime() {
    return TimeOfDay(
      hour: ConfigProvider.instance.get(Settings.onThisDayNotificationHour),
      minute: ConfigProvider.instance.get(Settings.onThisDayNotificationMinute),
    );
  }

  static Future<void> _selectOnThisDayTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _onThisDayNotificationTime(),
      builder: (context, child) => AppDialogTransition(child: child!),
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

  static Future<void> _selectTimeRange(BuildContext context) async {
    final range = await showTimeRangePicker(context,
        initialRange: TimeManager.getReminderTimeRange());
    if (range == null) return;

    await TimeManager.setReminderTimeRange(range);
    if (ConfigProvider.instance.get(Settings.dailyReminders)) {
      await NotificationManager.instance.stopDailyReminders();
      await NotificationManager.instance.startScheduledDailyReminders();
    }
  }

  static Future<void> _setNotifications(
    Setting<bool> setting,
    bool value, {
    required Future<void> Function() start,
    required Future<void> Function() stop,
  }) async {
    if (!await NotificationManager.instance.hasNotificationPermission()) return;
    await (value ? start() : stop());
    await ConfigProvider.instance.set(setting, value);
  }

  static Future<void> _setDailyReminders(bool value) {
    return _setNotifications(
      Settings.dailyReminders,
      value,
      start: NotificationManager.instance.startScheduledDailyReminders,
      stop: NotificationManager.instance.stopDailyReminders,
    );
  }

  static Future<void> _setFixedReminderTime(bool value) async {
    await ConfigProvider.instance.set(Settings.setReminderTime, value);
    await NotificationManager.instance.stopDailyReminders();
    await NotificationManager.instance.startScheduledDailyReminders();
  }

  static Future<void> _setOnThisDay(bool value) {
    return _setNotifications(
      Settings.onThisDayNotifications,
      value,
      start: NotificationManager.instance.startOnThisDayNotifications,
      stop: NotificationManager.instance.stopOnThisDayNotifications,
    );
  }

  static String _onThisDayTime(BuildContext context) {
    return TimeManager.timeOfDayString(context, _onThisDayNotificationTime());
  }

  static String _dailyReminderTime(BuildContext context) {
    return ConfigProvider.instance.get(Settings.setReminderTime)
        ? TimeManager.timeOfDayString(
            context, TimeManager.scheduledReminderTime())
        : TimeManager.timeRangeString(
            context, TimeManager.getReminderTimeRange());
  }

  static List<Widget> buildCoreReminderSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOn = ConfigProvider.instance.get(Settings.dailyReminders);
    final isFixedTime = ConfigProvider.instance.get(Settings.setReminderTime);
    return [
      SettingsToggleRow(
          title: l10n.settingsDailyReminderTitle,
          subtitle: l10n.settingsDailyReminderDescription,
          value: isOn,
          onChanged: _setDailyReminders),
      SettingsDependents(
        enabled: isOn,
        child: SettingsActionRow(
            title: l10n.settingsReminderTime,
            subtitle: _dailyReminderTime(context),
            onTap: () =>
                isFixedTime ? _selectTime(context) : _selectTimeRange(context)),
      ),
      SettingsDependents(
        enabled: isOn,
        child: SettingsToggleRow(
            title: l10n.settingsFixedReminderTimeTitle,
            subtitle: l10n.settingsFixedReminderTimeDescription,
            value: isFixedTime,
            onChanged: _setFixedReminderTime),
      ),
    ];
  }

  static List<Widget> buildOnThisDaySettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOn = ConfigProvider.instance.get(Settings.onThisDayNotifications);
    return [
      SettingsToggleRow(
          title: l10n.flashbackOnThisDay,
          subtitle: l10n.settingsOnThisDayDescription,
          value: isOn,
          onChanged: _setOnThisDay),
      SettingsDependents(
        enabled: isOn,
        child: SettingsActionRow(
            title: l10n.settingsReminderTime,
            subtitle: _onThisDayTime(context),
            onTap: () => _selectOnThisDayTime(context)),
      ),
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
