import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TemplateSettings extends StatelessWidget {
  const TemplateSettings({super.key});

  void _showEditTemplatePopup(BuildContext context, Template? template) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => EditTemplate(template: template)));
  }

  Widget _templateList(BuildContext context) {
    final templatesProvider = Provider.of<TemplatesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final templates = templatesProvider.templates;
    final defaultTemplateId =
        configProvider.get(ConfigKey.defaultTemplate) as int?;

    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.noTemplatesDescription),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isDefault = defaultTemplateId == template.id;
        return ListTile(
          title: Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16, top: 8.0, bottom: 8.0),
            child: Text(
              template.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
                onPressed: () async {
                  await configProvider.set(
                      ConfigKey.defaultTemplate, isDefault ? -1 : template.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  if (isDefault) {
                    await configProvider.set(ConfigKey.defaultTemplate, -1);
                  }
                  await templatesProvider.remove(template);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditTemplatePopup(context, template),
              ),
            ],
          ),
          onTap: () => _showEditTemplatePopup(context, template),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTemplatesTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showEditTemplatePopup(context, null),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _templateList(context),
      ),
    );
  }
}
