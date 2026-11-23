// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/utils/attachment_mime.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareEntry({
  required String text,
  required List<EntryAttachment> attachments,
}) async {
  final files = <XFile>[];
  final fileNames = <String>[];
  for (final attachment in attachments) {
    final localPath = await AttachmentStorage.instance
        .getLocalPath(attachment.filePath, attachment.type);
    if (localPath == null) continue;
    files.add(XFile(localPath,
        mimeType: attachmentMimeType(attachment.filePath, attachment.type)));
    fileNames.add(attachment.filePath);
  }
  await SharePlus.instance.share(ShareParams(
      text: text,
      files: files.isEmpty ? null : files,
      fileNameOverrides: files.isEmpty ? null : fileNames));
}
