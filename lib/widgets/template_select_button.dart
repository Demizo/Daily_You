import 'package:daily_you/models/template.dart';
import 'package:daily_you/template_renderer.dart';
import 'package:daily_you/widgets/template_select.dart';
import 'package:flutter/material.dart';

class TemplateSelectButton extends StatelessWidget {
  const TemplateSelectButton({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  String _getTemplateText(BuildContext context, Template template) {
    return TemplateRenderer.populate(context, template.text ?? "");
  }

  void _showTemplateSelectPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TemplateSelect(
          onTemplatesSelected: (Template template) {
            final templateText = _getTemplateText(context, template);
            if (controller.text.isNotEmpty) {
              if (controller.selection.isValid) {
                int cursorPos = controller.selection.base.offset;
                final beforeText = controller.text.substring(0, cursorPos);
                final afterText = controller.text.substring(cursorPos);
                controller.text = beforeText + templateText + afterText;
                controller.selection = TextSelection.collapsed(
                    offset: cursorPos + templateText.length);
              } else {
                controller.text += "\n$templateText";
              }
            } else {
              controller.text = templateText;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => _showTemplateSelectPopup(context),
        icon: Icon(
          Icons.note_add_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ));
  }
}
