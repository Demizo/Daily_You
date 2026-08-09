import 'package:daily_you/models/template.dart';
import 'package:daily_you/widgets/markdown_toolbar.dart';
import 'package:flutter/material.dart';

class EditToolbar extends StatelessWidget {
  const EditToolbar({
    super.key,
    required this.controller,
    required this.undoController,
    required this.focusNode,
    this.trailer,
    this.showTemplateButton = true,
    this.onTemplateInserted,
  });

  final TextEditingController controller;
  final UndoHistoryController undoController;
  final FocusNode focusNode;
  final Widget? trailer;
  final bool showTemplateButton;
  final void Function(Template template)? onTemplateInserted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MarkdownToolbar(
            controller: controller,
            focusNode: focusNode,
            undoController: undoController,
            showTemplateButton: showTemplateButton,
            onTemplateInserted: onTemplateInserted,
          ),
        ),
        if (trailer != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: trailer!,
          ),
      ],
    );
  }
}
