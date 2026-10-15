// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

Future<T?> showDayMenu<T>(
  BuildContext dayContext, {
  required List<PopupMenuEntry<T>> items,
}) {
  final RenderBox cell = dayContext.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(dayContext).context.findRenderObject() as RenderBox;

  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      cell.localToGlobal(cell.size.bottomLeft(Offset.zero), ancestor: overlay),
      cell.localToGlobal(cell.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  return showMenu<T>(
    context: dayContext,
    position: position,
    menuPadding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: items,
  );
}
