import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

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
    List<Template> templates = await Template.getAll();
    setState(() {
      _templates = templates;
    });
  }

  void _showEditTemplatePopup(BuildContext context, Template? template) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => EditTemplate(
              template: template,
              onTemplateSaved: () {
                _loadTemplates();
                widget.onTemplatesUpdated();
              },
            )));
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
                    await Template.delete(template.id!);
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
      body: _buildTemplatesList(),
    );
  }
}
