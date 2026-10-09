import 'package:app_settings/app_settings.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/notification_manager.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart' as sdk_material show TimeOfDay;
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:time_range_picker/time_range_picker.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();

  static Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeManager.scheduledReminderTime(),
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
    ThemeData theme = Theme.of(context);
    final currentRange = TimeManager.getReminderTimeRange();
    TimeRange? range = await showTimeRangePicker(
        context: context,
        toText: "",
        fromText: "",
        use24HourFormat: ConfigProvider.instance.is24HourFormat(),
        start: sdk_material.TimeOfDay(
            hour: currentRange.start.hour, minute: currentRange.start.minute),
        end: sdk_material.TimeOfDay(
            hour: currentRange.end.hour, minute: currentRange.end.minute),
        ticks: 24,
        handlerColor: theme.colorScheme.primary,
        strokeColor: theme.colorScheme.primary,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.disabledColor.withValues(alpha: 0.2),
        ticksColor: theme.colorScheme.surface,
        interval: Duration(minutes: 10),
        ticksWidth: 2,
        autoAdjustLabels: false,
        labels: [
          for (final hour in [0, 6, 12, 18])
            ClockLabel.fromTime(
                time: sdk_material.TimeOfDay(hour: hour, minute: 0),
                text: DateFormat.j(TimeManager.currentLocale(context)).format(
                    TimeManager.addTimeOfDay(
                        TimeManager.startOfDay(DateTime.now()),
                        TimeOfDay(hour: hour, minute: 0)))),
        ]);
    if (range != null) {
      await TimeManager.setReminderTimeRange((
        start: TimeOfDay(
            hour: range.startTime.hour, minute: range.startTime.minute),
        end: TimeOfDay(hour: range.endTime.hour, minute: range.endTime.minute),
      ));
      if (ConfigProvider.instance.get(Settings.dailyReminders)) {
        await NotificationManager.instance.stopDailyReminders();
        await NotificationManager.instance.startScheduledDailyReminders();
      }
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
      if (configProvider.get(Settings.dailyReminders))
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.reminderDaysTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildWeekdaySelector(context, configProvider),
            ],
          ),
        ),
    ];
  }

  static Widget _buildWeekdaySelector(
      BuildContext context, ConfigProvider configProvider) {
    final daysStr = configProvider.get(Settings.reminderDays);
    final selectedDays = daysStr
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();

    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 1; i <= 7; i++)
          FilterChip(
            label: Text(labels[i - 1]),
            selected: selectedDays.contains(i),
            showCheckmark: false,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(4),
            onSelected: (selected) async {
              final newSet = Set<int>.from(selectedDays);
              if (selected) {
                newSet.add(i);
              } else {
                if (newSet.length > 1) {
                  newSet.remove(i);
                }
              }
              final joined = (newSet.toList()..sort()).join(',');
              await configProvider.set(Settings.reminderDays, joined);
            },
          ),
      ],
    );
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
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(),
          ),
          SettingsToggle(
            title: AppLocalizations.of(context)!.alwaysOpenNewLogTitle,
            hint: AppLocalizations.of(context)!.alwaysOpenNewLogDescription,
            setting: Settings.alwaysOpenNewLog,
            onChanged: (value) async {
              await configProvider.set(Settings.alwaysOpenNewLog, value);
            },
          ),
        ],
      ),
    );
  }
}
