import 'dart:ui';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/markdown_preview_styles.dart';
import 'package:daily_you/widgets/editor_action_bar/editor_keyboard_session.dart';
import 'package:daily_you/widgets/markdown_preview_controller.dart';
import 'package:daily_you/widgets/markdown_preview_decorations.dart';
import 'package:flutter/material.dart';

class EntryTextField extends StatefulWidget {
  final MarkdownPreviewController controller;
  final FocusNode focusNode;
  final UndoHistoryController undoController;
  final ScrollController? scrollController;
  final EdgeInsets scrollPadding;
  final EdgeInsets contentPadding;
  final TextAlignVertical? textAlignVertical;

  const EntryTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.undoController,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.contentPadding =
        const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    this.textAlignVertical,
  });

  @override
  State<EntryTextField> createState() => _EntryTextFieldState();
}

class _EntryTextFieldState extends State<EntryTextField> {
  ScrollController? _ownedScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ??
      (_ownedScrollController ??= ScrollController());

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styles = MarkdownPreviewStyles.fromTheme(context);
    final session = EditorKeyboardSessionScope.maybeOf(context);
    final baseStyle = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 16,
      color: theme.colorScheme.onSurface,
    );
    final strutStyle = StrutStyle.fromTextStyle(baseStyle);

    final field = TextField(
      onTap: session?.resume,
      controller: widget.controller,
      undoController: widget.undoController,
      focusNode: widget.focusNode,
      scrollController: _scrollController,
      maxLines: null,
      expands: true,
      selectionWidthStyle: BoxWidthStyle.tight,
      selectionHeightStyle: MarkdownPreviewDecorations.heightStyle,
      scrollPadding: widget.scrollPadding,
      strutStyle: strutStyle,
      spellCheckConfiguration: SpellCheckConfiguration(
          spellCheckService: widget.controller.spellCheckService),
      contextMenuBuilder: (context, editor) {
        final suggestions = widget.controller.spellCheckMenuItems(editor);
        if (suggestions.isEmpty) {
          return AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editor);
        }
        return SpellCheckSuggestionsToolbar(
          anchor: SpellCheckSuggestionsToolbar.getToolbarAnchor(
              editor.contextMenuAnchors),
          buttonItems: suggestions,
        );
      },
      textCapitalization: TextCapitalization.sentences,
      textAlignVertical: widget.textAlignVertical,
      style: baseStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: widget.contentPadding,
        hintText: AppLocalizations.of(context)!.writeSomethingHint,
      ),
    );

    return MarkdownPreviewDecorations(
      controller: widget.controller,
      scrollController: _scrollController,
      barColor: styles.quote,
      panelColor: styles.codeBackground,
      child: field,
    );
  }
}
