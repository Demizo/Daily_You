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
  late final FocusNode _focusNode;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 6, bottom: 0, right: 8),
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
        Card(
            child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 0, bottom: 0, right: 8),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
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
          ),
        ))
      ],
    );
  }
}
