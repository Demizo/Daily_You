import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/template_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TemplateSettings extends StatelessWidget {
  const TemplateSettings({super.key});

  void _showTemplateManagementPopup(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => TemplateManager()));
  }

  List<DropdownMenuItem<int>> _buildDefaultTemplateDropdownItems(
      BuildContext context) {
    final templatesProvider = Provider.of<TemplatesProvider>(context);
    var dropdownItems = templatesProvider.templates.map((Template template) {
      return DropdownMenuItem<int>(
        value: template.id,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 180),
          child: Text(
            template.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
    dropdownItems.add(DropdownMenuItem<int>(
      value: -1,
      child: Text(AppLocalizations.of(context)!.noTemplateTitle),
    ));
    return dropdownItems;
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTemplatesTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsDropdown<int>(
            title: AppLocalizations.of(context)!.settingsDefaultTemplate,
            value: configProvider.get(ConfigKey.defaultTemplate),
            options: _buildDefaultTemplateDropdownItems(context),
            onChanged: (int? newValue) {
              configProvider.set(ConfigKey.defaultTemplate, newValue);
            },
          ),
          SettingsIconAction(
              title: AppLocalizations.of(context)!.manageTemplates,
              icon: Icon(Icons.edit_document),
              onPressed: () => _showTemplateManagementPopup(context)),
        ],
      ),
    );
  }
}
