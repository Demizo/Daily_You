// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class HideSemanticsWhileDragging extends StatefulWidget {
  final Widget child;

  const HideSemanticsWhileDragging({super.key, required this.child});

  @override
  State<HideSemanticsWhileDragging> createState() =>
      _HideSemanticsWhileDraggingState();
}

class _HideSemanticsWhileDraggingState
    extends State<HideSemanticsWhileDragging> {
  bool _hidden = false;

  void _setHidden(bool hidden) {
    if (hidden != _hidden) setState(() => _hidden = hidden);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _setHidden(notification.dragDetails != null);
    } else if (notification is ScrollEndNotification) {
      _setHidden(false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ExcludeSemantics(excluding: _hidden, child: widget.child),
    );
  }
}
