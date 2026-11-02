// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/widgets/image_decoded_notification.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

class SnapshotWhileScrolling extends StatefulWidget {
  const SnapshotWhileScrolling({
    super.key,
    required this.scrolling,
    required this.child,
  });

  final ValueListenable<bool> scrolling;
  final Widget child;

  @override
  State<SnapshotWhileScrolling> createState() => _SnapshotWhileScrollingState();
}

class _SnapshotWhileScrollingState extends State<SnapshotWhileScrolling> {
  final _controller = SnapshotController();

  @override
  void initState() {
    super.initState();
    _controller.allowSnapshotting = widget.scrolling.value;
    widget.scrolling.addListener(_sync);
  }

  @override
  void didUpdateWidget(SnapshotWhileScrolling oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrolling == widget.scrolling) return;
    oldWidget.scrolling.removeListener(_sync);
    widget.scrolling.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.scrolling.removeListener(_sync);
    _controller.dispose();
    super.dispose();
  }

  void _sync() => _controller.allowSnapshotting = widget.scrolling.value;

  bool _resnapshot(ImageDecodedNotification notification) {
    if (_controller.allowSnapshotting) {
      _controller.allowSnapshotting = false;
      _controller.allowSnapshotting = true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ImageDecodedNotification>(
      onNotification: _resnapshot,
      child: SnapshotWidget(
        controller: _controller,
        mode: SnapshotMode.permissive,
        child: widget.child,
      ),
    );
  }
}
