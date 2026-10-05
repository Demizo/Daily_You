// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:material_ui/material_ui.dart';

extension AttachmentTypePresentation on AttachmentType {
  IconData get icon => switch (this) {
        AttachmentType.image => Icons.image_rounded,
        AttachmentType.video => Icons.videocam_rounded,
        AttachmentType.audio => Icons.audiotrack_rounded,
      };

  String label(AppLocalizations l10n) => switch (this) {
        AttachmentType.image => l10n.imagesTitle,
        AttachmentType.video => l10n.videoTitle,
        AttachmentType.audio => l10n.audioTitle,
      };
}
