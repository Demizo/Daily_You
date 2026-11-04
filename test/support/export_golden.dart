// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show dirname, join;

const _goldensRoot = 'test/fixtures/exports';
const _byteOrderMark = [0xEF, 0xBB, 0xBF];

Future<void> expectMatchesGolden(String name, List<int> actualBytes) async {
  final goldenFile = File(join(_goldensRoot, name));

  if (Platform.environment['UPDATE_GOLDENS'] == '1') {
    await Directory(dirname(goldenFile.path)).create(recursive: true);
    await goldenFile.writeAsBytes(actualBytes);
    return;
  }
  expect(_textOf(actualBytes), equals(_textOf(await goldenFile.readAsBytes())));
}

String _textOf(List<int> bytes) {
  final hasByteOrderMark = bytes.length >= _byteOrderMark.length &&
      [for (final (index, byte) in _byteOrderMark.indexed) bytes[index] == byte]
          .every((matches) => matches);
  return '${hasByteOrderMark ? '<byte order mark>' : ''}${utf8.decode(bytes)}';
}
