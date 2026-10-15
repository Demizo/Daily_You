// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:daily_you/storage/sync_progress.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:logging/logging.dart';

class ExternalSync {
  ExternalSync(this.previous, this.desired);

  final ExternalSyncSettings previous;
  final ExternalSyncSettings desired;

  static final Logger _logger = Logger('ExternalSync');

  List<SyncItem> get items => [
        for (final item in ExternalSyncSettings.items)
          if (desired.location(item) != null &&
              desired.location(item) != previous.location(item))
            item,
      ];

  bool get syncsLogs => items.contains(SyncItem.logs);

  List<AttachmentType> get attachmentTypes => [
        for (final item in items)
          if (item.attachmentType case final type?) type,
      ];

  bool get hasWork => items.isNotEmpty;

  Future<OperationOutcome> run(void Function(SyncProgress) onProgress) async {
    var databaseReplaced = false;
    try {
      if (items.isNotEmpty) onProgress(SyncProgress(items.first));
      await desired.save();

      if (syncsLogs) {
        final outcome = await AppDatabase.instance.syncFromExternalLocation();
        if (outcome.failed) {
          await previous.save();
          return outcome;
        }
        databaseReplaced = true;
      }

      if (hasWork) {
        await AttachmentStorage.instance.syncAttachmentFolders(syncsLogs,
            types: attachmentTypes, onProgress: onProgress);
      }
      return const OperationOutcome.succeeded();
    } catch (error, stackTrace) {
      _logger.severe(
          'Syncing with the external location failed', error, stackTrace);
      if (!databaseReplaced) await previous.save();
      return OperationOutcome.failed(error);
    }
  }
}
