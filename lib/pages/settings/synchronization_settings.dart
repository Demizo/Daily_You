import 'package:daily_you/backup_restore_utils.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/import_utils.dart';
import 'package:daily_you/utils/export_utils.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class SynchronizationSettings extends StatefulWidget {
  const SynchronizationSettings({super.key});

  @override
  State<SynchronizationSettings> createState() =>
      _SynchronizationSettingsState();
}

class _SynchronizationSettingsState extends State<SynchronizationSettings> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Synchronization"), // TODO: localization
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
              title: "Enable synchronization",
              settingsKey: ConfigKey.syncEnabled,
              onChanged: (value) {
                configProvider.set(ConfigKey.syncEnabled, value);
              }),
          if (configProvider.get(ConfigKey.syncEnabled)) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: Divider(),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<String>(
                      initialValue: configProvider.get(ConfigKey.syncProvider),
                      decoration: InputDecoration(
                        labelText: 'Sync Provider',
                        border: OutlineInputBorder(),
                      ),
                      items: <String>['none', 'Dropbox']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          configProvider.set(
                              ConfigKey.syncProvider, newValue ?? "none");
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  SettingsIconAction(title: "Synchronize", icon: Icon(Icons.sync), onPressed: () => {

                  })
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
