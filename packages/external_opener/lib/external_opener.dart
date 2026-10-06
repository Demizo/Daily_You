// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalOpener {
  static const MethodChannel _channel = MethodChannel('external_opener');

  static Future<bool> open(String path, String mimeType) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _channel.invokeMethod<bool>(
              'open', {'path': path, 'mimeType': mimeType}) ??
          false;
    }
    return launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);
  }
}
