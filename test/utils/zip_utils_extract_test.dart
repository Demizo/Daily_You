// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  late Directory work;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('zip_utils_extract');
  });

  tearDown(() => work.delete(recursive: true));

  test('extracts nested files with their exact bytes', () async {
    final input = await Directory(join(work.path, 'backup')).create();
    final video = Uint8List.fromList(List.generate(300000, (i) => i % 251));
    await Directory(join(input.path, 'Video')).create();
    await File(join(input.path, 'Video', 'clip.mp4')).writeAsBytes(video);
    await File(join(input.path, 'note.txt')).writeAsString('hello');
    final archive = join(work.path, 'backup.zip');
    await ZipUtils.compress(archive, [], [input.path]);

    final output = join(work.path, 'restored');
    await ZipUtils.extract(archive, output);

    final restoredVideo =
        File(join(output, 'backup', 'Video', 'clip.mp4')).readAsBytesSync();
    expect(restoredVideo, equals(video));
    expect(
        File(join(output, 'backup', 'note.txt')).readAsStringSync(), 'hello');
  });

  test('extracts an older deflated archive', () async {
    final photo = Uint8List.fromList(List.generate(50000, (i) => i % 7));
    final path = join(work.path, 'deflated.zip');
    await File(path).writeAsBytes(ZipEncoder()
        .encodeBytes(Archive()..add(ArchiveFile.bytes('Images/a.jpg', photo))));

    await ZipUtils.extract(path, join(work.path, 'restored'));

    expect(
        File(join(work.path, 'restored', 'Images', 'a.jpg')).readAsBytesSync(),
        photo);
  });

  Future<String> archiveOf(List<ArchiveFile> files) async {
    final archive = Archive();
    for (final file in files) {
      archive.add(file);
    }
    final path = join(work.path, 'crafted.zip');
    await File(path).writeAsBytes(ZipEncoder().encodeBytes(archive));
    return path;
  }

  group('an entry that resolves outside the output folder', () {
    for (final name in [
      '../escaped.txt',
      'Images/../../escaped.txt',
      'Images/../../../../tmp/escaped.txt'
    ]) {
      test('$name is rejected and nothing is written outside', () async {
        final output = join(work.path, 'restored');
        final archive = await archiveOf([
          ArchiveFile.string('fine.txt', 'fine'),
          ArchiveFile.string(name, 'evil'),
        ]);

        await expectLater(ZipUtils.extract(archive, output), throwsA(anything));

        expect(File(join(work.path, 'escaped.txt')).existsSync(), isFalse);
        expect(File('/tmp/escaped.txt').existsSync(), isFalse);
      });
    }

    test('a directory entry with .. is rejected', () async {
      final output = join(work.path, 'restored');
      final archive = await archiveOf([ArchiveFile.directory('../outside/')]);

      await expectLater(ZipUtils.extract(archive, output), throwsA(anything));

      expect(Directory(join(work.path, 'outside')).existsSync(), isFalse);
    });

    test('a leading slash is read as relative to the output folder', () async {
      final output = join(work.path, 'restored');
      final archive =
          await archiveOf([ArchiveFile.string('/Images/a.jpg', 'picture')]);

      await ZipUtils.extract(archive, output);

      expect(
          File(join(output, 'Images', 'a.jpg')).readAsStringSync(), 'picture');
    });
  });
}
