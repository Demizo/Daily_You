// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';

Future<List<ImportedAttachment>> existingImageAttachments(
    Iterable<File> files, DateTime timeCreate) async {
  final attachments = <ImportedAttachment>[];
  for (final file in files) {
    if (!await file.exists()) continue;
    attachments.add(ImportedAttachment(
      type: AttachmentType.image,
      rank: attachments.length,
      timeCreate: timeCreate,
      media: FileMedia(file),
    ));
  }
  return attachments;
}
