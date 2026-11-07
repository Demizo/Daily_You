// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/utils/markdown_formatting.dart';
import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/text_editing.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/editor_action_bar/toolbar_menu_action.dart';
import 'package:daily_you/widgets/icons/svg_icon.dart';
import 'package:material_ui/material_ui.dart';

@immutable
class ToolbarAction {
  final Widget icon;
  final FutureOr<void> Function()? onPressed;

  final List<ToolbarMenuAction>? menu;

  final bool Function()? isActive;

  /// For actions that may launch an external activity. Focus must be manually restored
  final bool mayLeaveApp;

  const ToolbarAction({
    required this.icon,
    this.onPressed,
    this.menu,
    this.isActive,
    this.mayLeaveApp = false,
  }) : assert((onPressed == null) != (menu == null),
            'Provide exactly one of onPressed or menu');
}

List<ToolbarAction> markdownActions(
    BuildContext context, TextEditingController controller) {
  ToolbarAction toggle(Widget icon, MarkdownConstruct construct) =>
      ToolbarAction(
        icon: icon,
        onPressed: () => toggleMarkdown(controller, construct),
        isActive: () => isMarkdownActive(controller, construct),
      );

  return [
    toggle(const Icon(Icons.format_list_bulleted_rounded),
        MarkdownConstruct.bulletList),
    ToolbarAction(
      icon: const Icon(Icons.text_fields_rounded),
      onPressed: () => _toggleHeader(context, controller),
      isActive: () => isMarkdownActive(controller, MarkdownConstruct.header),
    ),
    toggle(const Icon(Icons.format_bold_rounded), MarkdownConstruct.bold),
    toggle(const Icon(Icons.format_italic_rounded), MarkdownConstruct.italic),
    toggle(const SvgIcon('assets/icons/format_ink_highlighter.svg'),
        MarkdownConstruct.highlight),
    toggle(const Icon(Icons.format_strikethrough_rounded),
        MarkdownConstruct.strikethrough),
    toggle(
        const Icon(Icons.format_quote_rounded), MarkdownConstruct.blockquote),
    toggle(const Icon(Icons.link_rounded), MarkdownConstruct.link),
  ];
}

Future<void> _toggleHeader(
    BuildContext context, TextEditingController controller) async {
  if (removeMarkdown(controller, MarkdownConstruct.header)) return;

  final level = await showAppDialog<int>(
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
