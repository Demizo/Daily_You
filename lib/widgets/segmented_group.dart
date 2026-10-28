// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class SegmentedGroup extends StatelessWidget {
  const SegmentedGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final last = children.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index <= last; index++)
          SegmentedRow(
            isFirst: index == 0,
            isLast: index == last,
            child: children[index],
          ),
      ],
    );
  }
}

class SegmentedRow extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  final bool isFirst;
  final bool isLast;
  final Widget child;

  static const Radius _outerRadius = Radius.circular(16);
  static const Radius _innerRadius = Radius.circular(4);
  static const double _gap = 2;
  static const double _hoverAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : _gap),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? _outerRadius : _innerRadius,
            bottom: isLast ? _outerRadius : _innerRadius,
          ),
        ),
        child: Theme(
          data: theme.copyWith(
            hoverColor:
                theme.colorScheme.onSurface.withValues(alpha: _hoverAlpha),
          ),
          child: child,
        ),
      ),
    );
  }
}
