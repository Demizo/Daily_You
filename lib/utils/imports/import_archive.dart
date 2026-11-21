// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:path/path.dart';

const _zipSignature = [0x50, 0x4B, 0x03, 0x04];
const extractedArchiveFolderName = 'archive_contents';

Future<String?> extractIfArchive(ImportSource source) async {
  final handle = await source.file.open();
  final List<int> header;
  try {
    header = await handle.read(_zipSignature.length);
  } finally {
    await handle.close();
  }
  if (!_hasZipSignature(header)) return null;

  final extractedPath = join(source.directoryPath, extractedArchiveFolderName);
  await ZipUtils.extract(source.file.path, extractedPath);
  return extractedPath;
}

bool _hasZipSignature(List<int> header) =>
    header.length == _zipSignature.length &&
    [for (final (index, byte) in _zipSignature.indexed) header[index] == byte]
        .every((matches) => matches);
