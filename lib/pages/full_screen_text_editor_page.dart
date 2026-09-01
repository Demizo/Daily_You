import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/entry_text_field.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
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
    final keyboardInset = EditorActionBarOverlay.keyboardInsetOf(context);

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
            return EditorActionBarOverlay(
              keyboardInset: keyboardInset,
              body: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: EditorActionBar.reservedHeight(context)),
                  child: EntryTextField(
                    controller: _controller,
                    undoController: _undoController,
                    focusNode: _focusNode,
                    textAlignVertical: TextAlignVertical.top,
                    contentPadding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 8.0),
                  ),
                ),
              ),
              actionBar: EditorActionBar(
                controller: _controller,
                undoController: _undoController,
                focusNode: _focusNode,
              ),
            );
          },
        ),
      ),
    );
  }
}
