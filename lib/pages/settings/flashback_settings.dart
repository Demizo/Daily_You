import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/settings_header.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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
              setting: Settings.showFlashbacks,
              onChanged: (value) {
                configProvider.set(Settings.showFlashbacks, value);
              }),
          if (configProvider.get(Settings.showFlashbacks))
            SettingsToggle(
                title: AppLocalizations.of(context)!
                    .settingsFlashbacksExcludeBadDays,
                setting: Settings.excludeBadDaysFromFlashbacks,
                onChanged: (value) {
                  configProvider.set(
                      Settings.excludeBadDaysFromFlashbacks, value);
                }),
          if (configProvider.get(Settings.showFlashbacks))
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
          title: AppLocalizations.of(context)!.flashbackOnThisDay,
          setting: Settings.showflashbackYearsAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashbackYearsAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackMonth(6),
          setting: Settings.showflashback6MonthsAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashback6MonthsAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackMonth(1),
          setting: Settings.showflashback1MonthAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashback1MonthAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackWeek(1),
          setting: Settings.showflashback1WeekAgo,
          onChanged: (value) {
            configProvider.set(Settings.showflashback1WeekAgo, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackGoodDay,
          setting: Settings.showflashbackGoodDay,
          onChanged: (value) {
            configProvider.set(Settings.showflashbackGoodDay, value);
          }),
      SettingsToggle(
          title: AppLocalizations.of(context)!.flashbackRandomDay,
          setting: Settings.showflashbackRandomDay,
          onChanged: (value) {
            configProvider.set(Settings.showflashbackRandomDay, value);
          }),
    ];
  }
}
