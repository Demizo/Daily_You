import 'package:app_settings/app_settings.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:time_range_picker/time_range_picker.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeManager.scheduledReminderTime(),
    );

    if (picked != null) {
      await ConfigProvider.instance
          .set(ConfigKey.scheduledReminderHour, picked.hour);
      await ConfigProvider.instance
          .set(ConfigKey.scheduledReminderMinute, picked.minute);
      if (ConfigProvider.instance.get(ConfigKey.dailyReminders)) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
    }
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    ThemeData theme = Theme.of(context);
    TimeRange currentRange = TimeManager.getReminderTimeRange();
    TimeRange? range = await showTimeRangePicker(
        context: context,
        toText: "",
        fromText: "",
        use24HourFormat: ConfigProvider.instance.is24HourFormat(),
        start: currentRange.startTime,
        end: currentRange.endTime,
        ticks: 24,
        handlerColor: theme.colorScheme.primary,
        strokeColor: theme.colorScheme.primary,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.disabledColor.withOpacity(0.2),
        ticksColor: theme.colorScheme.surface,
        interval: Duration(minutes: 10),
        ticksWidth: 2,
        autoAdjustLabels: false,
        labels: [
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 0, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 0, minute: 0)))),
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 6, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 6, minute: 0)))),
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 12, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 12, minute: 0)))),
          ClockLabel.fromTime(
              time: TimeOfDay(hour: 18, minute: 0),
              text: DateFormat.j(WidgetsBinding
                      .instance.platformDispatcher.locale
                      .toString())
                  .format(TimeManager.addTimeOfDay(
                      TimeManager.startOfDay(DateTime.now()),
                      TimeOfDay(hour: 18, minute: 0)))),
        ]);
    if (range != null) {
      await TimeManager.setReminderTimeRange(range);
      if (ConfigProvider.instance.get(ConfigKey.dailyReminders)) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
    }
  }

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
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsDailyReminderTitle,
              hint: AppLocalizations.of(context)!
                  .settingsDailyReminderDescription,
              settingsKey: ConfigKey.dailyReminders,
              onChanged: (value) async {
                if (await NotificationManager.instance
                    .hasNotificationPermission()) {
                  if (value) {
                    await NotificationManager.instance
                        .startScheduledDailyReminders();
                  } else {
                    await NotificationManager.instance.stopDailyReminders();
                  }
                  await configProvider.set(ConfigKey.dailyReminders, value);
                }
              }),
          if (configProvider.get(ConfigKey.dailyReminders))
            configProvider.get(ConfigKey.setReminderTime)
                ? SettingsIconAction(
                    title: AppLocalizations.of(context)!.settingsReminderTime,
                    hint: TimeManager.timeOfDayString(
                        TimeManager.scheduledReminderTime()),
                    icon: Icon(Icons.schedule_rounded),
                    onPressed: () async {
                      _selectTime(context);
                    })
                : SettingsIconAction(
                    title: AppLocalizations.of(context)!.settingsReminderTime,
                    hint: TimeManager.timeRangeString(
                        TimeManager.getReminderTimeRange()),
                    icon: Icon(Icons.timelapse_rounded),
                    onPressed: () async {
                      _selectTimeRange(context);
                    }),
          if (configProvider.get(ConfigKey.dailyReminders))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsFixedReminderTimeTitle,
                hint: AppLocalizations.of(context)!
                    .settingsFixedReminderTimeDescription,
                settingsKey: ConfigKey.setReminderTime,
                onChanged: (value) async {
                  await configProvider.set(ConfigKey.setReminderTime, value);
                  await NotificationManager.instance.stopDailyReminders();
                  await NotificationManager.instance
                      .startScheduledDailyReminders();
                }),
          if (configProvider.get(ConfigKey.dailyReminders))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsAlwaysSendReminderTitle,
                hint: AppLocalizations.of(context)!
                    .settingsAlwaysSendReminderDescription,
                settingsKey: ConfigKey.alwaysRemind,
                onChanged: (value) async {
                  await configProvider.set(ConfigKey.alwaysRemind, value);
                }),
          if (configProvider.get(ConfigKey.dailyReminders))
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
