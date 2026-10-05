// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive_io.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  late Directory work;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('zip_utils_compress');
  });

  tearDown(() => work.delete(recursive: true));

  Future<String> folderWith(String name, Map<String, String> files) async {
    final folder = await Directory(join(work.path, name)).create();
    for (final MapEntry(key: fileName, value: content) in files.entries) {
      await File(join(folder.path, fileName)).writeAsString(content);
    }
    return folder.path;
  }

  test('progress rises through several folders without restarting', () async {
    final images = await folderWith(
        'Images', {for (var i = 0; i < 10; i++) 'image_$i.jpg': 'a' * 1000});
    final audio = await folderWith('Audio', {'note.m4a': 'b' * 5000});
    final video = await folderWith('Video', {'clip.mp4': 'c' * 20000});
    final progress = <double>[];

    await ZipUtils.compress(
        join(work.path, 'backup.zip'), [], [images, audio, video],
        onProgress: progress.add);

    expect(progress, isNotEmpty);
    expect([...progress]..sort(), progress);
    expect(progress.last, closeTo(100, 0.001));
  });

  test('files are added under the archive path given, uncopied', () async {
    final source = File(join(work.path, 'source.bin'))
      ..writeAsStringSync('video bytes');
    final notes = await folderWith('logs', {'log.md': 'note'});
    final archive = join(work.path, 'export.zip');
    final progress = <double>[];

    await ZipUtils.compress(archive, [], [notes],
        filesByArchivePath: {'logs/Video/video_1.mp4': source.path},
        onProgress: progress.add);
    await ZipUtils.extract(archive, join(work.path, 'restored'));

    final restored = join(work.path, 'restored', 'logs');
    expect(File(join(restored, 'Video', 'video_1.mp4')).readAsStringSync(),
        'video bytes');
    expect(File(join(restored, 'log.md')).readAsStringSync(), 'note');
    expect(progress.last, closeTo(100, 0.001));
    expect(Directory(work.path).listSync().map((e) => e.path),
        isNot(contains(contains('video_1'))));
  });

  test('entries are stored without compression', () async {
    final images = await folderWith('Images', {'image.jpg': 'a' * 5000});
    final source = File(join(work.path, 'source.bin'))
      ..writeAsStringSync('b' * 5000);
    final archive = join(work.path, 'backup.zip');

    await ZipUtils.compress(archive, [], [images],
        filesByArchivePath: {'logs/Video/clip.mp4': source.path});

    final entries = ZipDecoder()
        .decodeStream(InputFileStream(archive))
        .where((entry) => entry.isFile);
    expect(entries, hasLength(2));
    expect(entries.map((entry) => entry.compression),
        everyElement(CompressionType.none));
  });

  test('a large file is zipped and extracted without being held in memory',
      () async {
    const megabytes = 200;
    final folder = await Directory(join(work.path, 'Video')).create();
    final chunk = List.generate(1024 * 1024, (index) => index % 251);
    final sink = File(join(folder.path, 'clip.mp4')).openWrite();
    for (var index = 0; index < megabytes; index++) {
      sink.add(chunk);
    }
    await sink.close();
    final archive = join(work.path, 'backup.zip');

    Future<int> peakResidentMegabytes(Future<void> Function() action) async {
      final baseline = ProcessInfo.currentRss;
      var peak = baseline;
      final timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
        peak = max(peak, ProcessInfo.currentRss);
      });
      await action();
      timer.cancel();
      return (peak - baseline) ~/ (1024 * 1024);
    }

    final compressPeak = await peakResidentMegabytes(
        () => ZipUtils.compress(archive, [], [folder.path]));
    final extractPeak = await peakResidentMegabytes(
        () => ZipUtils.extract(archive, join(work.path, 'restored')));

    expect(compressPeak, lessThan(megabytes ~/ 2));
    expect(extractPeak, lessThan(megabytes ~/ 2));
    expect(File(join(work.path, 'restored', 'Video', 'clip.mp4')).lengthSync(),
        megabytes * 1024 * 1024);
  });
}
