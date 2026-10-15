// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' show basename;
import 'package:path_provider/path_provider.dart';

const String recordingTemporaryPrefix = 'daily_you_recording_';

final Logger _logger = Logger('RecordingTemporaryFiles');

Future<void> deleteStaleRecordings({
  Directory? directory,
  Duration maxAge = const Duration(days: 1),
  DateTime? now,
}) async {
  try {
    directory ??= await getTemporaryDirectory();
    if (!await directory.exists()) return;
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    await for (final entity in directory.list()) {
      if (entity is! File ||
          !basename(entity.path).startsWith(recordingTemporaryPrefix)) {
        continue;
      }
      try {
        if ((await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      } catch (error) {
        _logger.warning('Could not remove ${entity.path}', error);
      }
    }
  } catch (error, stackTrace) {
    _logger.warning('Sweeping stale recordings failed', error, stackTrace);
  }
}
