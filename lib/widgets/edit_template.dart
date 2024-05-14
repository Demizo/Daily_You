import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';

class EditTemplate extends StatefulWidget {
  final Template? template;
  final Function onTemplateSaved;

  EditTemplate({this.template, required this.onTemplateSaved});

  @override
  State<EditTemplate> createState() => _EditTemplateState();
}

class _EditTemplateState extends State<EditTemplate> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _textController = TextEditingController(text: widget.template?.text ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (_formKey.currentState!.validate()) {
      if (widget.template == null) {
        await EntriesDatabase.instance.createTemplate(Template(
            name: _nameController.text,
            text: _textController.text,
            timeCreate: DateTime.now(),
            timeModified: DateTime.now()));
      } else {
        await EntriesDatabase.instance.updateTemplate(widget.template!.copy(
            name: _nameController.text,
            text: _textController.text,
            timeModified: DateTime.now()));
      }
      widget.onTemplateSaved();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template == null ? 'Add Template' : 'Edit Template'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Template Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(labelText: 'Template Text'),
              maxLines: null,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter text';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Discard'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Save'),
          onPressed: _saveTemplate,
        ),
      ],
    );
  }
}
