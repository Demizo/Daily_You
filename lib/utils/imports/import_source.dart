// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:path/path.dart';

enum ImportSourceKind { file, archive }

class ImportSource {
  const ImportSource(this.directoryPath, this.fileName);

  final String directoryPath;
  final String fileName;

  File get file => File(join(directoryPath, fileName));
}
