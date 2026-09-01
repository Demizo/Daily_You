import 'package:daily_you/widgets/editor_action_bar.dart';
import 'package:daily_you/widgets/entry_text_field.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    widget.textEditingController.text = widget.text;
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= EditorActionBar.wideBreakpoint;
    final showExpandButton = isWide && widget.onExpand != null;

    return Stack(
      children: [
        Card.filled(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 8, top: 2, bottom: 0, right: 8),
            child: EntryTextField(
              controller: widget.textEditingController,
              undoController: widget.undoHistoryController,
              focusNode: widget.focusNode,
              scrollController: _scrollController,
              // Add padding so cursor avoids action bar
              scrollPadding: EdgeInsets.only(
                left: 20.0,
                top: 20.0,
                right: 20.0,
                bottom: 20.0 + EditorActionBar.reservedHeight(context),
              ),
            ),
          ),
        ),
        if (showExpandButton)
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
}
