// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:app_settings/app_settings.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:daily_you/widgets/time_range_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();

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

  static List<Widget> buildCoreReminderSettings(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return [
      SettingsToggle(
          title: AppLocalizations.of(context)!.settingsDailyReminderTitle,
          hint: AppLocalizations.of(context)!.settingsDailyReminderDescription,
          setting: Settings.dailyReminders,
          onChanged: (value) async {
            if (await NotificationManager.instance
                .hasNotificationPermission()) {
              if (value) {
                await NotificationManager.instance
                    .startScheduledDailyReminders();
              } else {
                await NotificationManager.instance.stopDailyReminders();
              }
              await configProvider.set(Settings.dailyReminders, value);
            }
          }),
      if (configProvider.get(Settings.dailyReminders))
        configProvider.get(Settings.setReminderTime)
            ? SettingsIconAction(
                title: AppLocalizations.of(context)!.settingsReminderTime,
                hint: TimeManager.timeOfDayString(
                    context, TimeManager.scheduledReminderTime()),
                icon: Icon(Icons.schedule_rounded),
                onPressed: () async {
                  _selectTime(context);
                })
            : SettingsIconAction(
                title: AppLocalizations.of(context)!.settingsReminderTime,
                hint: TimeManager.timeRangeString(
                    context, TimeManager.getReminderTimeRange()),
                icon: Icon(Icons.timelapse_rounded),
                onPressed: () async {
                  _selectTimeRange(context);
                }),
      if (configProvider.get(Settings.dailyReminders))
        SettingsToggle(
            title: AppLocalizations.of(context)!.settingsFixedReminderTimeTitle,
            hint: AppLocalizations.of(context)!
                .settingsFixedReminderTimeDescription,
            setting: Settings.setReminderTime,
            onChanged: (value) async {
              await configProvider.set(Settings.setReminderTime, value);
              await NotificationManager.instance.stopDailyReminders();
              await NotificationManager.instance.startScheduledDailyReminders();
            }),
    ];
  }

  static List<Widget> buildOnThisDaySettings(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return [
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackOnThisDay,
          hint: AppLocalizations.of(context)!.settingsOnThisDayDescription,
          setting: Settings.onThisDayNotifications,
          onChanged: (value) async {
            if (await NotificationManager.instance
                .hasNotificationPermission()) {
              if (value) {
                await NotificationManager.instance
                    .startOnThisDayNotifications();
              } else {
                await NotificationManager.instance.stopOnThisDayNotifications();
              }
              await configProvider.set(Settings.onThisDayNotifications, value);
            }
          }),
      if (configProvider.get(Settings.onThisDayNotifications))
        SettingsIconAction(
            title: AppLocalizations.of(context)!.settingsReminderTime,
            hint: TimeManager.timeOfDayString(
                context, NotificationSettings._onThisDayNotificationTime()),
            icon: Icon(Icons.schedule_rounded),
            onPressed: () async {
              NotificationSettings._selectOnThisDayTime(context);
            }),
    ];
  }
}

class _NotificationSettingsState extends State<NotificationSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsNotificationsTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ...NotificationSettings.buildCoreReminderSettings(context),
          if (configProvider.get(Settings.dailyReminders))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsAlwaysSendReminderTitle,
                hint: AppLocalizations.of(context)!
                    .settingsAlwaysSendReminderDescription,
                setting: Settings.alwaysRemind,
                onChanged: (value) async {
                  await configProvider.set(Settings.alwaysRemind, value);
                }),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(),
          ),
          ...NotificationSettings.buildOnThisDaySettings(context),
          if (configProvider.get(Settings.dailyReminders) ||
              configProvider.get(Settings.onThisDayNotifications))
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Divider(),
            ),
          if (configProvider.get(Settings.dailyReminders) ||
              configProvider.get(Settings.onThisDayNotifications))
            SettingsIconAction(
                title: AppLocalizations.of(context)!
                    .settingsCustomizeNotificationTitle,
                icon: Icon(Icons.edit_notifications_rounded),
                onPressed: () => AppSettings.openAppSettings(
                    type: AppSettingsType.notification)),
        ],
      ),
    );
  }
}
