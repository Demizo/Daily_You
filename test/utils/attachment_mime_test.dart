// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/utils/attachment_mime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives a specific type from the extension', () {
    expect(attachmentMimeType('a.mp4', AttachmentType.video), 'video/mp4');
    expect(attachmentMimeType('a.M4A', AttachmentType.audio), 'audio/mp4');
    expect(attachmentMimeType('a.jpg', AttachmentType.image), 'image/jpeg');
  });

  test('falls back to a wildcard for the attachment type', () {
    expect(attachmentMimeType('a.xyz', AttachmentType.video), 'video/*');
    expect(attachmentMimeType('noextension', AttachmentType.audio), 'audio/*');
  });
}
