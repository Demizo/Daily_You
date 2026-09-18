import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/auto_backup_schedule.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AutoBackupSettingsDialog extends StatelessWidget {
  const AutoBackupSettingsDialog({super.key});

  Future<void> _pickLocation() async {
    final directory = await StoragePicker.pickDirectory();
    if (directory == null) return;
    await ConfigProvider.instance
        .set(Settings.autoBackupLocationUri, directory.uri);
  }

  Future<void> _pickTime(BuildContext context) async {
    final configProvider = ConfigProvider.instance;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: configProvider.get(Settings.autoBackupHour),
        minute: configProvider.get(Settings.autoBackupMinute),
      ),
    );
    if (picked == null) return;
    await configProvider.set(Settings.autoBackupHour, picked.hour);
    await configProvider.set(Settings.autoBackupMinute, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final locationUri = configProvider.get(Settings.autoBackupLocationUri);

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.settingsAutoBackup),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsAutoBackupLocation,
              hint: StoragePicker.displayName(locationUri),
              icon: Icon(Icons.folder_rounded),
              onPressed: _pickLocation,
            ),
            SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsAutoBackupTime,
              hint: TimeManager.timeOfDayString(
                  context,
                  TimeOfDay(
                    hour: configProvider.get(Settings.autoBackupHour),
                    minute: configProvider.get(Settings.autoBackupMinute),
                  )),
              icon: Icon(Icons.access_time_rounded),
              onPressed: () async => _pickTime(context),
            ),
            SettingsDropdown<String>(
              title: AppLocalizations.of(context)!.settingsAutoBackupInterval,
              value: configProvider.get(Settings.autoBackupInterval),
              options: [
                for (final interval in AutoBackupInterval.values)
                  DropdownMenuItem(
                      value: interval.key,
                      child: Text(interval.label(context))),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await configProvider.set(Settings.autoBackupInterval, value);
              },
            ),
            SettingsDropdown<int>(
              title: AppLocalizations.of(context)!.settingsAutoBackupMaxCount,
              value: configProvider.get(Settings.autoBackupMaxCount),
              options: [
                DropdownMenuItem(value: 1, child: Text("1")),
                DropdownMenuItem(value: 3, child: Text("3")),
                DropdownMenuItem(value: 5, child: Text("5")),
                DropdownMenuItem(value: 10, child: Text("10")),
                DropdownMenuItem(
                    value: 0,
                    child: Text(AppLocalizations.of(context)!
                        .settingsAutoBackupKeepAll)),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await configProvider.set(Settings.autoBackupMaxCount, value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
