// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.isIncrease, required this.text});

  final bool isIncrease;
  final String text;

  static TrendChip? fromChange(
    num? change,
    String Function(num amount) format,
  ) =>
      change == null
          ? null
          : TrendChip(isIncrease: change > 0, text: format(change.abs()));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isIncrease
        ? colorScheme.secondaryContainer
        : colorScheme.tertiaryContainer;
    final foregroundColor = isIncrease
        ? colorScheme.onSecondaryContainer
        : colorScheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(5, 2, 8, 2),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isIncrease
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: foregroundColor,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
