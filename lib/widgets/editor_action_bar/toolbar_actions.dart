import 'dart:async';

import 'package:daily_you/utils/text_editing.dart';
import 'package:flutter/material.dart';

@immutable
class ToolbarAction {
  final IconData icon;
  final FutureOr<void> Function() onPressed;

  /// For actions that may launch an external activity. Focus must be manually restored
  final bool mayLeaveApp;

  const ToolbarAction({
    required this.icon,
    required this.onPressed,
    this.mayLeaveApp = false,
  });
}

List<ToolbarAction> markdownActions(
    BuildContext context, TextEditingController controller) {
  return [
    ToolbarAction(
      icon: Icons.text_fields_rounded,
      onPressed: () => _insertHeader(context, controller),
    ),
    ToolbarAction(
      icon: Icons.format_bold_rounded,
      onPressed: () => wrapSelection(controller, '**'),
    ),
    ToolbarAction(
      icon: Icons.format_italic_rounded,
      onPressed: () => wrapSelection(controller, '_'),
    ),
    ToolbarAction(
      icon: Icons.format_list_bulleted_rounded,
      onPressed: () => insertLinePrefix(controller, '-'),
    ),
    ToolbarAction(
      icon: Icons.format_quote_rounded,
      onPressed: () => insertLinePrefix(controller, '>'),
    ),
    ToolbarAction(
      icon: Icons.link_rounded,
      onPressed: () => wrapSelection(controller, '[', ']()'),
    ),
    ToolbarAction(
      icon: Icons.format_strikethrough_rounded,
      onPressed: () => wrapSelection(controller, '~~'),
    ),
  ];
}

Future<void> _insertHeader(
    BuildContext context, TextEditingController controller) async {
  final level = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var level = 1; level <= 6; level++)
            ListTile(
              title: Text('H$level',
                  style: TextStyle(fontSize: 28 - 2 * level.toDouble())),
              onTap: () => Navigator.pop(context, level),
            ),
        ],
      ),
    ),
  );
  if (level != null) insertLinePrefix(controller, '#' * level);
}
