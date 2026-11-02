// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class PerformanceHint {
  static const MethodChannel _channel = MethodChannel('performance_hint');

  static void install() {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) _channel.invokeMethod<void>('boost');
  }
}
