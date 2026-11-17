// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class OnboardingScope extends InheritedWidget {
  const OnboardingScope({
    super.key,
    required this.ambient,
    required this.position,
    required this.transitioning,
    required this.onFinish,
    required super.child,
  });

  final Animation<double> ambient;
  final ValueListenable<double> position;
  final ValueListenable<bool> transitioning;
  final VoidCallback onFinish;

  static OnboardingScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingScope>()!;

  @override
  bool updateShouldNotify(OnboardingScope oldWidget) =>
      ambient != oldWidget.ambient ||
      position != oldWidget.position ||
      transitioning != oldWidget.transitioning;
}
