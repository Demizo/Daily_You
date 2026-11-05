// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class SegmentedGroup extends StatelessWidget {
  const SegmentedGroup({
    super.key,
    required this.children,
    this.emphasized = false,
  });

  final List<Widget> children;
  final bool emphasized;

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
            emphasized: emphasized,
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
    this.emphasized = false,
  });

  final bool isFirst;
  final bool isLast;
  final bool emphasized;
  final Widget child;

  static const Radius _outerRadius = Radius.circular(16);
  static const Radius _innerRadius = Radius.circular(4);
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : _gap),
      child: Material(
        color: emphasized
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? _outerRadius : _innerRadius,
            bottom: isLast ? _outerRadius : _innerRadius,
          ),
        ),
        child: emphasized
            ? ListTileTheme.merge(
                iconColor: colorScheme.primary,
                textColor: colorScheme.onPrimaryContainer,
                child: child,
              )
            : child,
      ),
    );
  }
}
