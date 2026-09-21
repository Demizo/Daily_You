import 'dart:io';

import 'package:daily_you/utils/cancellation_token.dart';
import 'package:daily_you/utils/zip_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory work;
  late Directory inputFolder;
  late String archive;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('zip_utils_cancellation');
    archive = join(work.path, 'backup.zip');
    inputFolder = await Directory(join(work.path, 'images')).create();
    for (var i = 0; i < 20; i++) {
      await File(join(inputFolder.path, 'image_$i.jpg'))
          .writeAsString('picture $i' * 1000);
    }
  });

  tearDown(() => work.delete(recursive: true));

  test('a pre-cancelled token stops compression before it starts', () async {
    final token = CancellationToken()..cancel();

    await expectLater(
        ZipUtils.compress(archive, [], [inputFolder.path],
            cancellationToken: token),
        throwsA(isA<BackupCancelledException>()));
    expect(await File(archive).exists(), isFalse);
  });

  test('cancelling mid-compress stops the archive isolate', () async {
    final token = CancellationToken();

    final result = ZipUtils.compress(archive, [], [inputFolder.path],
        cancellationToken: token, onProgress: (_) => token.cancel());

    await expectLater(result, throwsA(isA<BackupCancelledException>()));
  });

  test('an uncancelled token still compresses normally', () async {
    final token = CancellationToken();

    await ZipUtils.compress(archive, [], [inputFolder.path],
        cancellationToken: token);

    expect(await File(archive).exists(), isTrue);
    expect(token.isCancelled, isFalse);
  });
}
