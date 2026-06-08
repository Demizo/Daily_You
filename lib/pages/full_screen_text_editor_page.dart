import 'dart:ui';

import 'package:daily_you/widgets/edit_toolbar.dart';
import 'package:daily_you/widgets/template_select_button.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:word_count/word_count.dart';

class FullScreenTextEditorPage extends StatefulWidget {
  final String initialText;

  const FullScreenTextEditorPage({
    super.key,
    required this.initialText,
  });

  @override
  State<FullScreenTextEditorPage> createState() =>
      _FullScreenTextEditorPageState();
}

class _FullScreenTextEditorPageState extends State<FullScreenTextEditorPage> {
  late final TextEditingController _controller;
  late final UndoHistoryController _undoController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _undoController = UndoHistoryController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _undoController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _close,
          ),
          title: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) => Text(
              AppLocalizations.of(context)!
                  .wordCount(wordsCount(_controller.text)),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                Expanded(
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: TextField(
                      controller: _controller,
                      undoController: _undoController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      selectionWidthStyle: BoxWidthStyle.tight,
                      spellCheckConfiguration: SpellCheckConfiguration(
                          spellCheckService: DefaultSpellCheckService()),
                      textCapitalization: TextCapitalization.sentences,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 8.0),
                        hintText:
                            AppLocalizations.of(context)!.writeSomethingHint,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: EditToolbar(
                    controller: _controller,
                    undoController: _undoController,
                    focusNode: _focusNode,
                    trailer: TemplateSelectButton(controller: _controller),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
