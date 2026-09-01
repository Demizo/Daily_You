import 'dart:ui';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/editor_action_bar/editor_keyboard_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EntryTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final UndoHistoryController undoController;
  final ScrollController? scrollController;
  final EdgeInsets scrollPadding;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlignVertical? textAlignVertical;

  const EntryTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.undoController,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.contentPadding,
    this.textAlignVertical,
  });

  @override
  Widget build(BuildContext context) {
    final session = EditorKeyboardSessionScope.maybeOf(context);
    return TextField(
      onTap: session?.resume,
      controller: controller,
      undoController: undoController,
      focusNode: focusNode,
      scrollController: scrollController,
      maxLines: null,
      expands: true,
      selectionWidthStyle: BoxWidthStyle.tight,
      scrollPadding: scrollPadding,
      spellCheckConfiguration: SpellCheckConfiguration(
          spellCheckService: DefaultSpellCheckService()),
      textCapitalization: TextCapitalization.sentences,
      textAlignVertical: textAlignVertical,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: contentPadding,
        hintText: AppLocalizations.of(context)!.writeSomethingHint,
      ),
    );
  }
}
