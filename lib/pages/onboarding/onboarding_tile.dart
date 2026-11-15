// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class OnboardingTile extends StatelessWidget {
  static const double _minHeight = 88;
  static const double _compactMinHeight = 64;
  static const double _discSize = 52;
  static const double _compactDiscSize = 40;

  const OnboardingTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.selected = false,
    this.compact = false,
    required this.onTap,
  });

  OnboardingTile.task({
    super.key,
    required this.icon,
    required this.title,
    required bool done,
    required this.onTap,
  })  : trailing = OnboardingCompletion(done: done),
        selected = done,
        compact = false;

  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  static const Icon editIcon = Icon(Icons.edit_rounded, size: 20);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contentColor =
        selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: compact ? _compactMinHeight : _minHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: compact ? 8 : 14),
              child: Row(
                spacing: 16,
                children: [
                  SizedBox(
                    width: _discSize,
                    child: Center(
                      child: Container(
                        width: compact ? _compactDiscSize : _discSize,
                        height: compact ? _compactDiscSize : _discSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                        child: Icon(
                          icon,
                          size: compact ? 22 : 26,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: (compact
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(color: contentColor),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingCompletion extends StatelessWidget {
  static const double _size = 24;
  static const Duration _duration = Duration(milliseconds: 200);

  const OnboardingCompletion({super.key, required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = done ? colorScheme.primary : colorScheme.outline;
    return AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOutCubic,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? colorScheme.primary : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: AnimatedScale(
        duration: _duration,
        curve: Curves.easeOutBack,
        scale: done ? 1 : 0,
        child:
            Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary),
      ),
    );
  }
}

class OnboardingReveal extends StatelessWidget {
  const OnboardingReveal(
      {super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible ? child : const SizedBox(width: double.infinity),
    );
  }
}
