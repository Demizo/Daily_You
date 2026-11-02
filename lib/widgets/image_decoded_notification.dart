// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

class ImageDecodedNotification extends Notification {
  const ImageDecodedNotification();
}

Widget notifyWhenDecoded(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (frame != null && !wasSynchronouslyLoaded) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) const ImageDecodedNotification().dispatch(context);
    });
  }
  return child;
}
