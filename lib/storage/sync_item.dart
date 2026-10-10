// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';

enum SyncItem {
  logs,
  images,
  video,
  audio;

  static SyncItem forAttachments(AttachmentType type) => switch (type) {
        AttachmentType.image => images,
        AttachmentType.video => video,
        AttachmentType.audio => audio,
      };

  AttachmentType? get attachmentType => switch (this) {
        logs => null,
        images => AttachmentType.image,
        video => AttachmentType.video,
        audio => AttachmentType.audio,
      };

  String? get defaultSubfolder => attachmentType?.folderName;
}
