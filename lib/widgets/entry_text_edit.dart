import 'dart:io';

import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class EntryTextEditor extends StatefulWidget {
  final String text;
  final bool showTemplatesButton;
  final FocusNode focusNode;
  final TextEditingController textEditingController;

  const EntryTextEditor({
    super.key,
    this.text = '',
    required this.focusNode,
    required this.textEditingController,
    this.showTemplatesButton = true,
  });

  @override
  State<EntryTextEditor> createState() => _EntryTextEditorState();
}

class _EntryTextEditorState extends State<EntryTextEditor> {
  final ScrollController _scrollController = ScrollController();
  late List<Template> templates;
  bool isLoading = true;

  @override
  void initState() {
    widget.textEditingController.text = widget.text;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ])
      ],
    );
  }

  TextField entryTextField() {
    return TextField(
      scrollPadding: EdgeInsets.zero,
      controller: widget.textEditingController,
      focusNode: widget.focusNode,
      scrollController: _scrollController,
      minLines: 5,
      maxLines: widget.showTemplatesButton ? null : 10,
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
