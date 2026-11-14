// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:material_ui/material_ui.dart';

class GalleryInvite extends StatelessWidget {
  const GalleryInvite({super.key, required this.onPressed});

  static const double _buttonHeight = 56;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(child: _PlayfulPreview()),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                fixedSize: const Size.fromHeight(_buttonHeight),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                visualDensity: VisualDensity.standard,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.15,
                    ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded, size: 24),
              label: Text(AppLocalizations.of(context)!.newLogAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayfulPreview extends StatelessWidget {
  const _PlayfulPreview();

  static const double _cardWidth = 168;
  static const double _cardHeight = 148;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _cardWidth + 56,
      height: _cardHeight + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.12,
            child: _GhostCard(
              color: colorScheme.tertiaryContainer,
              lineColor: colorScheme.onTertiaryContainer,
              faceColor: colorScheme.tertiary,
              faceIcon: Icons.sentiment_satisfied_rounded,
            ),
          ),
          Transform.rotate(
            angle: -0.06,
            child: _GhostCard(
              color: colorScheme.primaryContainer,
              lineColor: colorScheme.onPrimaryContainer,
              faceColor: colorScheme.primary,
              faceIcon: Icons.sentiment_very_satisfied_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  const _GhostCard({
    required this.color,
    required this.lineColor,
    required this.faceColor,
    required this.faceIcon,
  });

  final Color color;
  final Color lineColor;
  final Color faceColor;
  final IconData faceIcon;

  @override
  Widget build(BuildContext context) {
    final placeholder = lineColor.withValues(alpha: 0.25);

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: SizedBox(height: height),
          ),
        );

    return SizedBox(
      width: _PlayfulPreview._cardWidth,
      height: _PlayfulPreview._cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(entryCardCornerRadius * 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: bar(0.5, 12)),
                  Icon(faceIcon, size: 28, color: faceColor),
                ],
              ),
              const SizedBox(height: 14),
              bar(1, 8),
              const SizedBox(height: 10),
              bar(0.85, 8),
              const SizedBox(height: 10),
              bar(0.55, 8),
              const SizedBox(height: 10),
              bar(0.7, 8),
            ],
          ),
        ),
      ),
    );
  }
}
