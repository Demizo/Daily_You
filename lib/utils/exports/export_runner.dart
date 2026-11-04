// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/time_manager.dart';
import 'package:daily_you/utils/exports/export_attachment_picker.dart';
import 'package:daily_you/utils/exports/export_registry.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

typedef ExportAttachmentTypePicker = Future<Set<AttachmentType>?> Function(
    BuildContext context);

typedef ExportDirectoryPicker = Future<PickedDirectory?> Function();

const _documentsFolderName = 'documents';
const _zipExtension = '.zip';
const _zipMimeType = 'application/zip';

Future<OperationOutcome> runExport(
  BuildContext context,
  void Function(String) updateStatus, {
  required ExportFormatOption option,
  ExportAttachmentTypePicker pickAttachmentTypes = pickExportAttachmentTypes,
  ExportDirectoryPicker pickDirectory = StoragePicker.pickDirectory,
}) async {
  final localizations = AppLocalizations.of(context)!;
  final locale = TimeManager.currentLocale(context);

  final includedTypes = await pickAttachmentTypes(context);
  if (includedTypes == null) return const OperationOutcome.cancelled();

  updateStatus("(1/2) 0%");

  final PickedDirectory? destination;
  try {
    destination = await pickDirectory();
  } catch (error) {
    return OperationOutcome.failed(error);
  }
  if (destination == null) return const OperationOutcome.cancelled();

  Directory? stagingDirectory;
  try {
    stagingDirectory =
        await (await getTemporaryDirectory()).createTemp('export_');
    final documentsDirectory =
        await Directory(join(stagingDirectory.path, _documentsFolderName))
            .create();

    final snapshot = await buildExportSnapshot(
        localizations: localizations,
        locale: locale,
        includedTypes: includedTypes,
        onProgress: (fraction) =>
            updateStatus("(1/2) ${(fraction * 100).round()}%"));
    final attachmentSources =
        await option.write(snapshot, LocalFileStore(documentsDirectory.path));

    final singleDocumentName =
        attachmentSources.isEmpty ? option.documentName : null;
    final exportName = _exportName(
        option.format,
        singleDocumentName == null
            ? _zipExtension
            : extension(singleDocumentName));

    final String exportPath;
    if (singleDocumentName == null) {
      exportPath = join(stagingDirectory.path, exportName);
      final documents = documentsDirectory.listSync();
      await ZipUtils.compress(
          exportPath,
          [for (final file in documents.whereType<File>()) file.path],
          [for (final folder in documents.whereType<Directory>()) folder.path],
          filesByArchivePath: attachmentSources,
          onProgress: (percent) => updateStatus("(2/2) ${percent.round()}%"));
    } else {
      exportPath = join(documentsDirectory.path, singleDocumentName);
    }

    updateStatus(localizations.tranferStatus("0"));
    await destination.copyFileInto(exportPath, exportName,
        mimeType: singleDocumentName == null
            ? _zipMimeType
            : option.documentMimeType!,
        onProgress: (percent) =>
            updateStatus(localizations.tranferStatus("${percent.round()}")));
    return const OperationOutcome.succeeded();
  } catch (error) {
    return OperationOutcome.failed(error);
  } finally {
    updateStatus(localizations.cleanUpStatus);
    if (stagingDirectory != null && await stagingDirectory.exists()) {
      await stagingDirectory.delete(recursive: true);
    }
  }
}

String _exportName(ExportFormat format, String extension) =>
    'daily_you_${format.name}_export_${DateTime.now().toIso8601String().replaceAll(':', '-')}$extension';
