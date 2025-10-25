import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/edit_toolbar.dart';
import 'package:daily_you/widgets/entry_text_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

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
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final UndoHistoryController _undoController = UndoHistoryController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    if (widget.template != null) {
      templateText = widget.template!.text ?? "";
    } else {
      templateText = "";
    }
    _textEditingController
        .addListener(() => templateText = _textEditingController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
    _undoController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (widget.template == null) {
      await Template.create(Template(
          name: _nameController.text,
          text: templateText,
          timeCreate: DateTime.now(),
          timeModified: DateTime.now()));
    } else {
      await Template.update(widget.template!.copy(
          name: _nameController.text,
          text: templateText,
          timeModified: DateTime.now()));
    }
    widget.onTemplateSaved();
    Navigator.of(context).pop();
  }

  Widget saveButton() {
    return IconButton(
      icon: const Icon(Icons.check),
      onPressed: () async {
        await _saveTemplate();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [saveButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints.loose(const Size.fromWidth(800)),
              child: ListView(
                padding: const EdgeInsets.only(left: 8, right: 8),
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
                    focusNode: _focusNode,
                    textEditingController: _textEditingController,
                    undoHistoryController: _undoController,
                    showTemplatesButton: false,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: EditToolbar(
              controller: _textEditingController,
              undoController: _undoController,
              focusNode: _focusNode,
              showTemplatesButton: false,
            ),
          ),
        ],
      ),
    );
  }
}
