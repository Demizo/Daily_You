import 'dart:io';

import 'package:daily_you/config_manager.dart';
import 'package:daily_you/entries_database.dart';
import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_toolbar/markdown_toolbar.dart';

class EntryTextEditor extends StatefulWidget {
  final String text;
  final ValueChanged<String> onChangedText;

  const EntryTextEditor(
      {super.key, this.text = '', required this.onChangedText});

  @override
  State<EntryTextEditor> createState() => _EntryTextEditorState();
}

class _EntryTextEditorState extends State<EntryTextEditor> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _focusNode;
  late List<Template> templates;
  bool isLoading = true;

  @override
  void initState() {
    _controller.text = widget.text;
    _controller.addListener(() => setState(() {
          widget.onChangedText(_controller.text);
        }));
    _focusNode = FocusNode();
    loadTemplates();

    super.initState();
  }

  Future loadTemplates() async {
    setState(() {
      isLoading = true;
    });

    templates = await EntriesDatabase.instance.getAllTemplates();

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (ConfigManager.instance.getField('useMarkdownToolbar'))
              Padding(
                padding:
                    const EdgeInsets.only(left: 4, top: 6, bottom: 0, right: 8),
                child: MarkdownToolbar(
                  useIncludedTextField: false,
                  controller: _controller,
                  focusNode: _focusNode,
                  width: 36,
                  height: 36,
                  spacing: 4,
                  hideImage: true,
                  hideCode: true,
                  hideLink: false,
                  hideCheckbox: true,
                  hideNumberedList: true,
                  hideHorizontalRule: true,
                  borderRadius: BorderRadius.circular(30),
                  iconColor: theme.colorScheme.onBackground,
                  backgroundColor: theme.cardColor,
                  dropdownTextColor: theme.colorScheme.onBackground,
                  collapsable: false,
                  alignCollapseButtonEnd: false,
                  italicCharacter: '_',
                ),
              ),
            if (!isLoading)
              DropdownButton<int>(
                  hint: Icon(
                    Icons.document_scanner_rounded,
                    color: theme.colorScheme.onBackground,
                  ),
                  underline: Container(),
                  value: ConfigManager.instance.getField("defaultTemplate"),
                  items: templates.map((Template template) {
                    return DropdownMenuItem<int>(
                        value: template.id, child: Text(template.name));
                  }).toList(),
                  onChanged: (templateId) async {
                    var template =
                        await EntriesDatabase.instance.getTemplate(templateId!);
                    if (template != null) {
                      setState(() {
                        _controller.text = template.text ?? "";
                        widget.onChangedText(_controller.text);
                      });
                    }
                  })
          ],
        ),
        Card(
            child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 0, right: 8),
          child: Platform.isAndroid
              ? Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  interactive: true,
                  radius: const Radius.circular(8),
                  child: entryTextField(),
                )
              : entryTextField(),
        ))
      ],
    );
  }

  TextField entryTextField() {
    return TextField(
      scrollPadding: EdgeInsets.zero,
      controller: _controller,
      focusNode: _focusNode,
      scrollController: _scrollController,
      minLines: 5,
      maxLines: 10,
      spellCheckConfiguration: SpellCheckConfiguration(
          spellCheckService: DefaultSpellCheckService()),
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Type something... (supports markdown)',
      ),
    );
  }
}
