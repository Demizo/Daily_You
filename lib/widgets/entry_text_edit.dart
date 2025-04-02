import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/template_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:markdown_toolbar/markdown_toolbar.dart';
import 'package:provider/provider.dart';

class EntryTextEditor extends StatefulWidget {
  final String text;
  final ValueChanged<String> onChangedText;
  final bool showTemplatesButton;

  const EntryTextEditor(
      {super.key,
      this.text = '',
      required this.onChangedText,
      this.showTemplatesButton = true});

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

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showTemplateSelectPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TemplateSelect(
          onTemplatesSelected: (Template template) {
            if (_controller.text.isNotEmpty) {
              _controller.text += "\n${template.text ?? ""}";
            } else {
              _controller.text = template.text ?? "";
            }
            widget.onChangedText(_controller.text);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (configProvider.get(ConfigKey.useMarkdownToolbar))
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
                  iconColor: theme.colorScheme.onSurface,
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  dropdownTextColor: theme.colorScheme.onSurface,
                  collapsable: false,
                  alignCollapseButtonEnd: false,
                  italicCharacter: '_',
                ),
              ),
          ],
        ),
        Stack(alignment: Alignment.topRight, children: [
          Card(
              child: Padding(
            padding:
                const EdgeInsets.only(left: 8, top: 2, bottom: 0, right: 8),
            child: Platform.isAndroid
                ? Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    radius: const Radius.circular(8),
                    child: entryTextField(),
                  )
                : entryTextField(),
          )),
          if (widget.showTemplatesButton)
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: IconButton(
                  onPressed: () => _showTemplateSelectPopup(context),
                  icon: Icon(
                    Icons.description_rounded,
                    color: theme.disabledColor,
                  )),
            ),
        ])
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
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: AppLocalizations.of(context)!.writeSomethingHint,
      ),
    );
  }
}
