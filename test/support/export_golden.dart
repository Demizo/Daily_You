// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show dirname, join;

const _goldensRoot = 'test/fixtures/exports';

Future<void> expectMatchesGolden(String name, List<int> actualBytes) async {
  final goldenFile = File(join(_goldensRoot, name));
  final actual = utf8.decode(actualBytes);

  if (Platform.environment['UPDATE_GOLDENS'] == '1') {
    await Directory(dirname(goldenFile.path)).create(recursive: true);
    await goldenFile.writeAsString(actual);
    return;
  }
  expect(actual, equals(await goldenFile.readAsString()));
}
