// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

const double contentMaxWidth = 800;

double contentSideInset(double viewportWidth) =>
    math.max(0, (viewportWidth - contentMaxWidth) / 2);

class ContentWidthLimit extends StatelessWidget {
  const ContentWidthLimit({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentMaxWidth),
        child: child,
      ),
    );
  }
}
