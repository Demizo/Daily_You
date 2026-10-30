// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/color_utils.dart';
import 'package:material_ui/material_ui.dart';

class ColorSwatchButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const ColorSwatchButton(
      {super.key, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(backgroundColor: color, radius: 16),
          Icon(
            Icons.palette_rounded,
            size: 20,
            color: contrastingTextColor(color),
          ),
        ],
      ),
    );
  }
}
