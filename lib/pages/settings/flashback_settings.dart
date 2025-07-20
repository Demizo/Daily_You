import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/settings_header.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class FlashbackSettings extends StatefulWidget {
  const FlashbackSettings({super.key});

  @override
  State<FlashbackSettings> createState() => _FlashbackSettingsPageState();
}

class _FlashbackSettingsPageState extends State<FlashbackSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.flashbacksTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
              title: AppLocalizations.of(context)!.settingsShowFlashbacks,
              settingsKey: ConfigKey.showFlashbacks,
              onChanged: (value) {
                configProvider.set(ConfigKey.showFlashbacks, value);
              }),
          if (configProvider.get(ConfigKey.showFlashbacks))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsFlashbacksExcludeBadDays,
                settingsKey: ConfigKey.excludeBadDaysFromFlashbacks,
                onChanged: (value) {
                  configProvider.set(
                      ConfigKey.excludeBadDaysFromFlashbacks, value);
                }),
          if (configProvider.get(ConfigKey.showFlashbacks))
            ...buildFlashbackOptions(configProvider),
        ],
      ),
    );
  }

  List<Widget> buildFlashbackOptions(ConfigProvider configProvider) {
    return [
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child:
            SettingsHeader(text: AppLocalizations.of(context)!.flashbacksTitle),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Divider(),
      ),
      SettingsToggle(
          title: AppLocalizations.of(context)!
              .flashbackYear(2)
              .replaceFirst("2", "?"), // Display "? Years Ago"
          settingsKey: ConfigKey.showflashbackYearsAgo,
          onChanged: (value) {
            configProvider.set(ConfigKey.showflashbackYearsAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackMonth(6),
          settingsKey: ConfigKey.showflashback6MonthsAgo,
          onChanged: (value) {
            configProvider.set(ConfigKey.showflashback6MonthsAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackMonth(1),
          settingsKey: ConfigKey.showflashback1MonthAgo,
          onChanged: (value) {
            configProvider.set(ConfigKey.showflashback1MonthAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackWeek(1),
          settingsKey: ConfigKey.showflashback1WeekAgo,
          onChanged: (value) {
            configProvider.set(ConfigKey.showflashback1WeekAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackGoodDay,
          settingsKey: ConfigKey.showflashbackGoodDay,
          onChanged: (value) {
            configProvider.set(ConfigKey.showflashbackGoodDay, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackRandomDay,
          settingsKey: ConfigKey.showflashbackRandomDay,
          onChanged: (value) {
            configProvider.set(ConfigKey.showflashbackRandomDay, value);
          }),
    ];
  }
}
