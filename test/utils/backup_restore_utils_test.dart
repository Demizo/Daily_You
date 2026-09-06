import 'dart:typed_data';

import 'package:daily_you/storage/in_memory_file_store.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class BlindFileStore extends InMemoryFileStore {
  @override
  Future<Uint8List?> read(String name) async => null;
}

void main() {
  late InMemoryFileStore destination;

  Uint8List bytesOf(String text) => Uint8List.fromList(text.codeUnits);

  setUp(() => destination = InMemoryFileStore());

  test('copies every backed up image into the destination', () async {
    final backup = InMemoryFileStore();
    await backup.write('one.jpg', bytesOf('one'));
    await backup.write('two.jpg', bytesOf('two'));

    await BackupRestoreUtils.restoreImages(backup, destination);

    expect(await destination.list(), unorderedEquals(['one.jpg', 'two.jpg']));
    expect(await destination.read('one.jpg'), equals(bytesOf('one')));
  });

  test('overwrites an image the destination already holds', () async {
    final backup = InMemoryFileStore();
    await backup.write('one.jpg', bytesOf('backed up'));
    await destination.write('one.jpg', bytesOf('stale'));

    await BackupRestoreUtils.restoreImages(backup, destination);

    expect(await destination.read('one.jpg'), equals(bytesOf('backed up')));
  });

  test('skips images the backup cannot read', () async {
    final backup = BlindFileStore();
    await backup.write('one.jpg', bytesOf('one'));

    await BackupRestoreUtils.restoreImages(backup, destination);

    expect(await destination.list(), isEmpty);
  });
}
