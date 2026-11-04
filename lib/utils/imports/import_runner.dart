// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_bundle.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/imports/import_writer.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

typedef ImportFilePicker = Future<PickedFile?> Function(
    {List<String>? allowedExtensions, List<String>? mimeTypes});

typedef ImportParser = Future<ImportBundle> Function(ImportSource source);

const _archiveName = 'archive.zip';
const _extractedFolderName = 'extracted';

Future<OperationOutcome> runImport(
  BuildContext context,
  void Function(String) updateStatus, {
  required ImportSourceKind kind,
  required ImportParser parse,
  List<String>? pickerExtensions,
  List<String>? pickerMimeTypes,
  ImportFilePicker pickFile = StoragePicker.pickFile,
}) async {
  final localizations = AppLocalizations.of(context)!;
  updateStatus("0%");

  final PickedFile? pickedFile;
  try {
    pickedFile = await pickFile(
        allowedExtensions: pickerExtensions, mimeTypes: pickerMimeTypes);
  } catch (error) {
    return OperationOutcome.failed(error);
  }
  if (pickedFile == null) return const OperationOutcome.cancelled();

  Directory? stagingDirectory;
  try {
    stagingDirectory =
        await (await getTemporaryDirectory()).createTemp('import_');
    final source = await _stage(
        pickedFile, kind, stagingDirectory, localizations, updateStatus);
    final bundle = await parse(source);
    return await ImportWriter().write(bundle, updateStatus);
  } catch (error) {
    return OperationOutcome.failed(error);
  } finally {
    updateStatus(localizations.cleanUpStatus);
    if (stagingDirectory != null && await stagingDirectory.exists()) {
      await stagingDirectory.delete(recursive: true);
    }
  }
}

Future<ImportSource> _stage(
  PickedFile pickedFile,
  ImportSourceKind kind,
  Directory stagingDirectory,
  AppLocalizations localizations,
  void Function(String) updateStatus,
) async {
  final stagedName = switch (kind) {
    ImportSourceKind.file => basename(pickedFile.name),
    ImportSourceKind.archive => _archiveName,
  };

  updateStatus(localizations.tranferStatus("0"));
  await pickedFile.copyInto(stagingDirectory.path, stagedName,
      onProgress: (percent) {
    updateStatus(localizations.tranferStatus("${percent.round()}"));
  });

  if (kind == ImportSourceKind.file) {
    return ImportSource(stagingDirectory.path, stagedName);
  }

  final extractedPath = join(stagingDirectory.path, _extractedFolderName);
  await ZipUtils.extract(
      join(stagingDirectory.path, stagedName), extractedPath);
  return ImportSource(extractedPath, pickedFile.name);
}
