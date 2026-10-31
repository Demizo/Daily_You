// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:material_ui/material_ui.dart';

final isDesktopPlatform =
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

class DesktopArrowButton extends StatelessWidget {
  const DesktopArrowButton({
    super.key,
    required this.forward,
    required this.onPressed,
  });

  final bool forward;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isRightToLeft = Directionality.of(context) == TextDirection.rtl;
    return IconButton.filledTonal(
      icon: Icon(forward != isRightToLeft
          ? Icons.chevron_right_rounded
          : Icons.chevron_left_rounded),
      onPressed: onPressed,
    );
  }
}
