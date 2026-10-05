// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/utils/recording_temporary_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('recordings'));
  tearDown(() => directory.deleteSync(recursive: true));

  File create(String name, {required Duration age}) {
    final file = File(join(directory.path, name))..createSync();
    file.setLastModifiedSync(DateTime.now().subtract(age));
    return file;
  }

  test('deletes only old recordings', () async {
    final stale = create('${recordingTemporaryPrefix}1.m4a',
        age: const Duration(days: 2));
    final fresh = create('${recordingTemporaryPrefix}2.m4a',
        age: const Duration(minutes: 5));
    final unrelated = create('other.m4a', age: const Duration(days: 30));

    await deleteStaleRecordings(directory: directory);

    expect(stale.existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
    expect(unrelated.existsSync(), isTrue);
  });
}
