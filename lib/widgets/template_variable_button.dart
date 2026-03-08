import 'package:daily_you/template_renderer.dart';
import 'package:flutter/material.dart';

class TemplateVariableButton extends StatelessWidget {
  const TemplateVariableButton({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  void _addVariableToText(BuildContext context, String variable) {
    if (controller.text.isNotEmpty) {
      if (controller.selection.isValid) {
        int cursorPos = controller.selection.base.offset;
        final beforeText = controller.text.substring(0, cursorPos);
        final afterText = controller.text.substring(cursorPos);
        controller.text = beforeText + variable + afterText;
        controller.selection =
            TextSelection.collapsed(offset: cursorPos + variable.length);
      } else {
        controller.text += variable;
      }
    } else {
      controller.text = variable;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      elevation: 1,
      child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: null, // Do nothing
          icon: Icon(
            Icons.add_circle_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          )),
      onSelected: (String newValue) {
        _addVariableToText(context, newValue);
      },
      itemBuilder: (BuildContext context) {
        final options = TemplateRenderer.getVariableList(context);
        return options.map((TemplateVariable option) {
          return PopupMenuItem(value: option.value, child: Text(option.label));
        }).toList();
      },
    );
  }
}
