import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TemplateManager extends StatelessWidget {
  const TemplateManager({super.key});

  void _showEditTemplatePopup(BuildContext context, Template? template) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => EditTemplate(
              template: template,
            )));
  }

  Widget _buildTemplatesList(BuildContext context) {
    final templatesProvider = Provider.of<TemplatesProvider>(context);
    final templates = templatesProvider.templates;

    if (templates.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context)!.noTemplatesDescription),
        ],
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
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
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    if (ConfigProvider.instance
                            .get(ConfigKey.defaultTemplate) ==
                        template.id!) {
                      await ConfigProvider.instance
                          .set(ConfigKey.defaultTemplate, -1);
                    }
                    await templatesProvider.remove(template);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditTemplatePopup(context, template);
                  },
                ),
              ],
            ),
            onTap: () {
              _showEditTemplatePopup(context, template);
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageTemplates),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              _showEditTemplatePopup(context, null);
            },
          ),
        ],
      ),
      body: _buildTemplatesList(context),
    );
  }
}
