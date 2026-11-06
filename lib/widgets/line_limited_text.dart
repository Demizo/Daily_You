// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

class LineLimitedText extends StatelessWidget {
  const LineLimitedText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = DefaultTextStyle.of(context).style.merge(style);
    final lineHeight = (TextPainter(
      text: TextSpan(text: text, style: resolvedStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout())
        .height;

    return LayoutBuilder(
      builder: (context, constraints) => Text(
        text,
        maxLines: constraints.hasBoundedHeight
            ? math.max(1, (constraints.maxHeight / lineHeight).floor())
            : null,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
