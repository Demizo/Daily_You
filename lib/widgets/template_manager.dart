import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:flutter/material.dart';

class TemplateManager extends StatefulWidget {
  final Function onTemplatesUpdated;

  TemplateManager({required this.onTemplatesUpdated});

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage Templates'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final template = _templates[index];
            return ListTile(
              title: Text(template.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _showEditTemplatePopup(context, template);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await EntriesDatabase.instance
                          .deleteTemplate(template.id!);
                      _loadTemplates();
                      widget.onTemplatesUpdated();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Add Template'),
          onPressed: () {
            _showEditTemplatePopup(context, null);
          },
        ),
      ],
    );
  }
}
