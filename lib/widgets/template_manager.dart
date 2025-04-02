import 'package:daily_you/config_provider.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TemplateManager extends StatefulWidget {
  final Function onTemplatesUpdated;

  const TemplateManager({super.key, required this.onTemplatesUpdated});

  @override
  State<TemplateManager> createState() => _TemplateManagementDialogState();
}

class _TemplateManagementDialogState extends State<TemplateManager> {
  List<Template> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    List<Template> templates = await EntriesDatabase.instance.getAllTemplates();
    setState(() {
      _templates = templates;
    });
  }

  void _showEditTemplatePopup(BuildContext context, Template? template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditTemplate(
          template: template,
          onTemplateSaved: () {
            _loadTemplates();
            widget.onTemplatesUpdated();
          },
        );
      },
    );
  }

  Widget _buildTemplatesList() {
    if (_templates.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context)!.noTemplatesDescription),
        ],
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return Card(
            child: ListTile(
              title: Padding(
                padding: const EdgeInsets.all(8.0),
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
                      await EntriesDatabase.instance
                          .deleteTemplate(template.id!);
                      if (ConfigProvider.instance
                              .get(ConfigKey.defaultTemplate) ==
                          template.id!) {
                        await ConfigProvider.instance
                            .set(ConfigKey.defaultTemplate, -1);
                      }
                      _loadTemplates();
                      widget.onTemplatesUpdated();
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
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.manageTemplates),
      content: SizedBox(width: double.maxFinite, child: _buildTemplatesList()),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: Text(AppLocalizations.of(context)!.newTemplate),
          onPressed: () {
            _showEditTemplatePopup(context, null);
          },
        ),
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
