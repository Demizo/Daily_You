// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class BottomFade extends StatelessWidget {
  const BottomFade({
    super.key,
    required this.color,
    required this.start,
    required this.end,
    required this.child,
  });

  final Color color;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0), color],
                  stops: [start, end],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
