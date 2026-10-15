// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:daily_you/storage/local_file_store.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  late Directory root;
  late LocalFileStore backup;
  late LocalFileStore destination;

  Uint8List bytesOf(String text) => Uint8List.fromList(text.codeUnits);

  setUp(() {
    root = Directory.systemTemp.createTempSync('restore_attachments');
    backup = LocalFileStore(Directory(join(root.path, 'backup')).path);
    destination = LocalFileStore(join(root.path, 'destination'));
    Directory(backup.directoryPath).createSync();
    Directory(destination.directoryPath).createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('copies every backed up image into the destination', () async {
    await backup.write('one.jpg', bytesOf('one'));
    await backup.write('two.jpg', bytesOf('two'));

    await BackupRestoreUtils.restoreAttachmentFiles(backup, destination);

    expect(await destination.list(), unorderedEquals(['one.jpg', 'two.jpg']));
    expect(await destination.read('one.jpg'), equals(bytesOf('one')));
  });

  test('overwrites an image the destination already holds', () async {
    await backup.write('one.jpg', bytesOf('backed up'));
    await destination.write('one.jpg', bytesOf('stale'));

    await BackupRestoreUtils.restoreAttachmentFiles(backup, destination);

    expect(await destination.read('one.jpg'), equals(bytesOf('backed up')));
  });

  test('restores nothing from an empty backup folder', () async {
    expect(await BackupRestoreUtils.restoreAttachmentFiles(backup, destination),
        isEmpty);

    expect(await destination.list(), isEmpty);
  });

  test('leaves no temporary file behind after restoring', () async {
    await backup.write('one.jpg', bytesOf('one'));

    await BackupRestoreUtils.restoreAttachmentFiles(backup, destination);

    expect(await destination.list(), equals(['one.jpg']));
  });

  test('a failed copy keeps the file the destination holds and is reported',
      () async {
    final unreadable = _UnreadableBackup(backup.directoryPath, 'two.jpg');
    await backup.write('one.jpg', bytesOf('one'));
    await destination.write('two.jpg', bytesOf('current'));

    final failed = await BackupRestoreUtils.restoreAttachmentFiles(
        unreadable, destination);

    expect(failed, equals(['two.jpg']));
    expect(await destination.read('two.jpg'), equals(bytesOf('current')));
    expect(await destination.read('one.jpg'), equals(bytesOf('one')));
    expect(await destination.list(), unorderedEquals(['one.jpg', 'two.jpg']));
  });
}

class _UnreadableBackup extends LocalFileStore {
  _UnreadableBackup(super.directoryPath, this.missingName);

  final String missingName;

  @override
  Future<List<String>> list() async => [...await super.list(), missingName];
}
