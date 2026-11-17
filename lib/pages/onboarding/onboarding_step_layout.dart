// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math' as math;

import 'package:daily_you/pages/onboarding/onboarding_scope.dart';
import 'package:daily_you/widgets/snapshot_while_scrolling.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingStepLayout extends StatelessWidget {
  static const double maxWidth = 480;
  static const double verticalPadding = 16;
  static const double _illustrationHeightFactor = 0.32;
  static const double _minIllustrationExtent = 120;
  static const double _maxIllustrationExtent = 240;

  static double illustrationExtent(double pageHeight) =>
      (pageHeight * _illustrationHeightFactor)
          .clamp(_minIllustrationExtent, _maxIllustrationExtent);

  const OnboardingStepLayout({
    super.key,
    required this.index,
    required this.illustration,
    required this.title,
    required this.description,
    this.children = const [],
  });

  final int index;
  final Widget illustration;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scope = OnboardingScope.of(context);
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final illustrationSize = illustrationExtent(constraints.maxHeight);
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: verticalPadding),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight:
                  math.max(0, constraints.maxHeight - 2 * verticalPadding),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _PageDelta(
                      index: index,
                      position: scope.position,
                      transitioning: scope.transitioning,
                      builder: (context, delta, child) => Transform.scale(
                        scale: 1 - 0.2 * delta.abs().clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: _fade(delta, 1.2),
                          child: child,
                        ),
                      ),
                      child: SizedBox(
                          width: double.infinity,
                          height: illustrationSize,
                          child: illustration),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: _PageDelta(
                          index: index,
                          position: scope.position,
                          transitioning: scope.transitioning,
                          builder: (context, delta, child) =>
                              Opacity(opacity: _fade(delta, 1.6), child: child),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                description,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              if (children.isNotEmpty)
                                const SizedBox(height: 24),
                              ...children,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  static double _fade(double delta, double rate) =>
      (1 - delta.abs() * rate).clamp(0.0, 1.0);
}

class _PageDelta extends StatelessWidget {
  const _PageDelta({
    required this.index,
    required this.position,
    required this.transitioning,
    required this.builder,
    required this.child,
  });

  final int index;
  final ValueListenable<double> position;
  final ValueListenable<bool> transitioning;
  final Widget Function(BuildContext context, double delta, Widget child)
      builder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: position,
      child: SnapshotWhileScrolling(scrolling: transitioning, child: child),
      builder: (context, value, child) =>
          builder(context, value - index, child!),
    );
  }
}
