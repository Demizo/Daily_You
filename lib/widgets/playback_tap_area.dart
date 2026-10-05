// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:material_ui/material_ui.dart';

class PlaybackTapArea extends StatelessWidget {
  const PlaybackTapArea({
    super.key,
    required this.playing,
    required this.onPlay,
    required this.onPause,
    required this.child,
  });

  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: playing ? onPause : onPlay,
      child: child,
    );
  }
}
