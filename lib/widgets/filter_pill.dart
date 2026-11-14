// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.child,
    this.icon,
    this.onPressed,
    this.onClear,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget? icon;
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onClear;
  final Color? backgroundColor;
  final Color? foregroundColor;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = onClear != null;
    final foreground = foregroundColor ??
        (isActive
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant);

    return Material(
      color: backgroundColor ??
          (isActive ? colorScheme.primaryContainer : Colors.transparent),
      shape: StadiumBorder(
        side: isActive
            ? BorderSide.none
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: 12,
              end: isActive ? 4 : 14,
            ),
            child: DefaultTextStyle.merge(
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: foreground),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground, size: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    child,
                    if (isActive)
                      InkResponse(
                        onTap: onClear,
                        containedInkWell: true,
                        highlightShape: BoxShape.circle,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Icon(
                            Icons.close_rounded,
                            semanticLabel:
                                AppLocalizations.of(context)!.clearFilter,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
