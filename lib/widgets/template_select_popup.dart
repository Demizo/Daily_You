import 'package:daily_you/models/template.dart';
import 'package:daily_you/template_renderer.dart';
import 'package:daily_you/widgets/template_select.dart';
import 'package:flutter/material.dart';

void showTemplateSelectPopup(
    BuildContext context, TextEditingController controller,
    {void Function(Template template)? onTemplateSelected}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return TemplateSelect(
        onTemplatesSelected: (Template template) {
          final templateText =
              TemplateRenderer.populate(context, template.text ?? "");
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
          onTemplateSelected?.call(template);
        },
      );
    },
  );
}
