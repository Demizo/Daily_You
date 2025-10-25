import 'package:daily_you/config_provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:daily_you/widgets/template_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TemplateSettings extends StatefulWidget {
  const TemplateSettings({super.key});

  @override
  State<TemplateSettings> createState() => _TemplateSettingsState();
}

class _TemplateSettingsState extends State<TemplateSettings> {
  List<Template> _templates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    List<Template> templates = await EntriesDatabase.instance.getAllTemplates();
    setState(() {
      _templates = templates;
      isLoading = false;
    });
  }

  void _showTemplateManagementPopup(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => TemplateManager(
              onTemplatesUpdated: _loadTemplates,
            )));
  }

  List<DropdownMenuItem<int>> _buildDefaultTemplateDropdownItems(
      BuildContext context) {
    var dropdownItems = _templates.map((Template template) {
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
          if (!isLoading)
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
