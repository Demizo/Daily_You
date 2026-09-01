import 'package:daily_you/models/template.dart';
import 'package:daily_you/template_renderer.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/template_select.dart';
import 'package:flutter/material.dart';

Future<void> showTemplateSelectPopup(
    BuildContext context, TextEditingController controller,
    {required FocusNode focusNode,
    void Function(Template template)? onTemplateSelected}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return TemplateSelect(
        onTemplatesSelected: (Template template) {
          final templateText =
              TemplateRenderer.populate(context, template.text ?? "");
          insertTemplateText(controller, templateText,
              hasFocus: focusNode.hasFocus);
          onTemplateSelected?.call(template);
        },
      );
    },
  );
}
