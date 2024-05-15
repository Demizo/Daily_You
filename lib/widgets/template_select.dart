import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';

class TemplateSelect extends StatefulWidget {
  final Function(Template template, bool insert) onTemplatesSelected;

  const TemplateSelect({super.key, required this.onTemplatesSelected});

  @override
  State<TemplateSelect> createState() => _TemplateSelectDialogState();
}

class _TemplateSelectDialogState extends State<TemplateSelect> {
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

  Widget _buildTemplatesList() {
    if (_templates.isEmpty) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Go to settings to create a template..."),
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
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      widget.onTemplatesSelected(template, true);
                      Navigator.of(context).pop();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_rounded),
                    onPressed: () {
                      widget.onTemplatesSelected(template, false);
                      Navigator.of(context).pop();
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
      title: const Text('Select or Add Template'),
      content: SizedBox(width: double.maxFinite, child: _buildTemplatesList()),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
