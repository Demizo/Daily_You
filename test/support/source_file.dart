// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

File sourceFile(String text) {
  final directory = Directory.systemTemp.createTempSync('source_file');
  addTearDown(() => directory.deleteSync(recursive: true));
  return File(join(directory.path, 'source.bin'))..writeAsStringSync(text);
}
