import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditTemplate extends StatefulWidget {
  final Template? template;
  final Function onTemplateSaved;

  const EditTemplate({super.key, this.template, required this.onTemplateSaved});

  @override
  State<EditTemplate> createState() => _EditTemplateState();
}

class _EditTemplateState extends State<EditTemplate> {
  late TextEditingController _nameController;
  late String templateText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    if (widget.template != null) {
      templateText = widget.template!.text ?? "";
    } else {
      templateText = "";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (widget.template == null) {
      await EntriesDatabase.instance.createTemplate(Template(
          name: _nameController.text,
          text: templateText,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()));
    } else {
      await EntriesDatabase.instance.updateTemplate(widget.template!.copy(
          name: _nameController.text,
          text: templateText,
          timeModified: DateTime.now()));
    }
    widget.onTemplateSaved();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                ),
                child: TextField(
                  controller: _nameController,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.words,
                  spellCheckConfiguration: SpellCheckConfiguration(
                      spellCheckService: DefaultSpellCheckService()),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context)!.titleHint,
                  ),
                ),
              ),
            ),
            EntryTextEditor(
              text: templateText,
              onChangedText: (text) => {templateText = text},
              showTemplatesButton: false,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: _saveTemplate,
                  child:
                      Text(MaterialLocalizations.of(context).saveButtonLabel),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
