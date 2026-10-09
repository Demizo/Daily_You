// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/settings_toggle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class EditorSettingsPage extends StatelessWidget {
  const EditorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = Provider.of<ConfigProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsEditorTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsToggle(
            title: l10n.settingsMarkdownTitle,
            hint: l10n.settingsMarkdownDescription,
            setting: Settings.markdownEnabled,
            onChanged: (val) async {
              await configProvider.set(Settings.markdownEnabled, val);
            },
          ),
          SettingsToggle(
            title: l10n.settingsAutocorrectTitle,
            hint: l10n.settingsAutocorrectDescription,
            setting: Settings.keyboardAutocorrect,
            onChanged: (val) async {
              await configProvider.set(Settings.keyboardAutocorrect, val);
            },
          ),
          SettingsToggle(
            title: l10n.settingsCapitalizationTitle,
            hint: l10n.settingsCapitalizationDescription,
            setting: Settings.keyboardCapitalization,
            onChanged: (val) async {
              await configProvider.set(Settings.keyboardCapitalization, val);
            },
          ),
        ],
      ),
    );
  }
}
