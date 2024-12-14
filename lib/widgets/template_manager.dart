import 'package:daily_you/config_manager.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter/material.dart';

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
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No templates created..."),
          ),
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
              title: Text(template.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await EntriesDatabase.instance
                          .deleteTemplate(template.id!);
                      if (ConfigManager.instance.getField("defaultTemplate") ==
                          template.id!) {
                        await ConfigManager.instance
                            .setField("defaultTemplate", -1);
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
      title: const Text('Manage Templates'),
      content: SizedBox(width: double.maxFinite, child: _buildTemplatesList()),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Template'),
          onPressed: () {
            _showEditTemplatePopup(context, null);
          },
        ),
      ],
    );
  }
}
