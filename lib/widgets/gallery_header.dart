// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/widgets/content_width_limit.dart';
import 'package:daily_you/widgets/entry_card_widget.dart';
import 'package:daily_you/widgets/gallery_filter_pills.dart';
import 'package:material_ui/material_ui.dart';

class GalleryHeader extends StatelessWidget {
  const GalleryHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onClearAll,
    required this.onSortPressed,
    this.resultCount,
    this.partialMatchCount = 0,
    this.onPartialMatchesPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onClearAll;
  final VoidCallback onSortPressed;
  final int? resultCount;
  final int partialMatchCount;
  final VoidCallback? onPartialMatchesPressed;

  static const double _controlHeight = 56;

  Widget _clearButton() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final rotation = Tween<double>(begin: 0.0, end: 0.5).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          );
          final scale = TweenSequence([
            TweenSequenceItem(
              tween: Tween<double>(begin: 0.0, end: 1.1)
                  .chain(CurveTween(curve: Curves.easeOut)),
              weight: 50,
            ),
            TweenSequenceItem(
              tween: Tween<double>(begin: 1.1, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeIn)),
              weight: 50,
            ),
          ]).animate(animation);
          return RotationTransition(
            turns: rotation,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: searchController.text.isNotEmpty
            ? IconButton(
                key: const ValueKey('clearButton'),
                visualDensity: const VisualDensity(
                    horizontal: VisualDensity.minimumDensity),
                icon: const Icon(Icons.clear),
                onPressed: onSearchCleared,
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      );

  Widget _buildCounts(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final countStyle = textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.logCount(count), style: countStyle),
          if (partialMatchCount > 0) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPartialMatchesPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  l10n.partialMatchCount(partialMatchCount),
                  style: countStyle?.copyWith(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = resultCount;

    return ColoredBox(
      color: colorScheme.surface,
      child: ContentWidthLimit(
        child: Padding(
          padding: EdgeInsets.only(bottom: count == null ? 12 : 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: entryCardMargin + galleryHorizontalPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchController,
                        builder: (context, _, __) => SearchBar(
                          controller: searchController,
                          elevation: const WidgetStatePropertyAll(0),
                          backgroundColor: WidgetStatePropertyAll(
                            colorScheme.secondaryContainer,
                          ),
                          constraints:
                              const BoxConstraints(minHeight: _controlHeight),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.only(left: 4, right: 4),
                          ),
                          hintText:
                              AppLocalizations.of(context)!.searchLogsHint,
                          leading: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: colorScheme.secondary,
                            ),
                          ),
                          trailing: [_clearButton()],
                          onChanged: onSearchChanged,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort_rounded),
                      onPressed: onSortPressed,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GalleryFilterPills(onClearAll: onClearAll),
              if (count != null) _buildCounts(context, count),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryHeaderEdge extends StatelessWidget {
  const GalleryHeaderEdge({super.key, required this.isElevated});

  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: entryCardCornerRadius,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: isElevated ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 150),
          builder: (context, elevation, _) => CustomPaint(
            painter: _ConcaveEdgePainter(
              color: colorScheme.surface,
              shadowColor:
                  colorScheme.shadow.withValues(alpha: 0.15 * elevation),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcaveEdgePainter extends CustomPainter {
  const _ConcaveEdgePainter({required this.color, required this.shadowColor});

  final Color color;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(entryCardCornerRadius);
    final panel = Path()
      ..addRRect(RRect.fromLTRBAndCorners(
        0,
        0,
        size.width,
        size.height * 4,
        topLeft: radius,
        topRight: radius,
      ));
    final headerShape = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(-8, -32, size.width + 8, size.height * 4)),
      panel,
    );

    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(headerShape, Paint()..color = color);
    canvas.save();
    canvas.clipPath(panel);
    canvas.drawPath(
      Path()..addRect(Rect.fromLTRB(-8, -32, size.width + 8, 2)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConcaveEdgePainter oldPainter) =>
      oldPainter.color != color || oldPainter.shadowColor != shadowColor;
}
