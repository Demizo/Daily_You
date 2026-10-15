// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:math';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/attachment_tile_background.dart';
import 'package:material_ui/material_ui.dart';

class AttachmentGrid extends StatelessWidget {
  AttachmentGrid({super.key, required List<EntryAttachment> attachments})
      : tileCount = attachments.length,
        tileBuilder = ((index) =>
            AttachmentTileBackground(attachment: attachments[index]));

  AttachmentGrid.fromPaths({
    super.key,
    required List<String> attachmentPaths,
    required Widget Function(String attachmentPath) pathTileBuilder,
  })  : tileCount = attachmentPaths.length,
        tileBuilder = ((index) => pathTileBuilder(attachmentPaths[index]));

  final int tileCount;
  final Widget Function(int index) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final count = min(tileCount, 4);
    Widget tile(int index) => Expanded(child: tileBuilder(index));
    const horizontalGap = SizedBox(width: 2);
    const verticalGap = SizedBox(height: 2);

    if (count == 1) {
      return tileBuilder(0);
    }

    if (count == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(0), horizontalGap, tile(1)],
      );
    }

    if (count == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(0),
          horizontalGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tile(1), verticalGap, tile(2)],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(0), horizontalGap, tile(1)],
          ),
        ),
        verticalGap,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tile(2), horizontalGap, tile(3)],
          ),
        ),
      ],
    );
  }
}
