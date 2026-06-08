import 'dart:ui';

import 'package:daily_you/models/template.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';

class EntryTextEditor extends StatefulWidget {
  final String text;
  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final UndoHistoryController undoHistoryController;
  final VoidCallback? onExpand;

  const EntryTextEditor({
    super.key,
    this.text = '',
    required this.focusNode,
    required this.textEditingController,
    required this.undoHistoryController,
    this.onExpand,
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
    final isWide = MediaQuery.of(context).size.width >= 600;
    final card = Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 2, bottom: 0, right: 8),
        child: entryTextField(),
      ),
    );

    if (!isWide || widget.onExpand == null) return card;

    return Stack(
      children: [
        card,
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.open_in_full_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: widget.onExpand,
          ),
        ),
      ],
    );
  }

  Widget entryTextField() {
    return TextField(
      controller: widget.textEditingController,
      undoController: widget.undoHistoryController,
      focusNode: widget.focusNode,
      scrollController: _scrollController,
      minLines: 5,
      maxLines: null,
      selectionWidthStyle: BoxWidthStyle.tight,
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
