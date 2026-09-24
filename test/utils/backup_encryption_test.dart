import 'dart:io';

import 'package:daily_you/utils/backup_encryption.dart';
import 'package:daily_you/utils/cancellation_token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' hide equals;

void main() {
  const secret = 'super secret message';
  late Directory work;
  late String plainFile;
  late String encryptedFile;

  setUp(() async {
    work = await Directory.systemTemp.createTemp('backup_encryption');
    plainFile = join(work.path, 'backup.zip');
    encryptedFile = join(work.path, 'backup.zip.enc');
    await File(plainFile).writeAsString(secret);
  });

  tearDown(() => work.delete(recursive: true));

  test('a file round trips through encryption and decryption', () async {
    await BackupEncryption.encryptFile(plainFile, encryptedFile, 'dolphin');

    final decrypted = join(work.path, 'decrypted.zip');
    await BackupEncryption.decryptFile(encryptedFile, decrypted, 'dolphin');

    expect(await File(decrypted).readAsString(), secret);
  });

  test('an encrypted file does not carry the plaintext', () async {
    await BackupEncryption.encryptFile(plainFile, encryptedFile, 'dolphin');

    final bytes = await File(encryptedFile).readAsBytes();
    expect(String.fromCharCodes(bytes).contains(secret), isFalse);
  });

  test('decrypting with the wrong password fails', () async {
    await BackupEncryption.encryptFile(plainFile, encryptedFile, 'dolphin');

    final decrypted = join(work.path, 'decrypted.zip');
    expect(BackupEncryption.decryptFile(encryptedFile, decrypted, 'wrong'),
        throwsA(isA<BackupDecryptionFailedException>()));
  });

  test('decrypting a file that was never encrypted fails', () async {
    final decrypted = join(work.path, 'decrypted.zip');
    expect(BackupEncryption.decryptFile(plainFile, decrypted, 'dolphin'),
        throwsA(isA<BackupDecryptionFailedException>()));
  });

  test('looksEncrypted recognizes an encrypted file but not a plain one',
      () async {
    await BackupEncryption.encryptFile(plainFile, encryptedFile, 'dolphin');

    expect(await BackupEncryption.looksEncrypted(File(encryptedFile)), isTrue);
    expect(await BackupEncryption.looksEncrypted(File(plainFile)), isFalse);
  });

  test('a large file round trips across multiple internal chunks', () async {
    final largeFile = join(work.path, 'large.zip');
    final sink = File(largeFile).openWrite();
    final chunk = List<int>.filled(1 << 16, 65); // 64 KiB of 'A'
    for (var i = 0; i < 20; i++) {
      sink.add(chunk);
    }
    await sink.close();

    await BackupEncryption.encryptFile(largeFile, encryptedFile, 'dolphin');
    final decrypted = join(work.path, 'decrypted.zip');
    await BackupEncryption.decryptFile(encryptedFile, decrypted, 'dolphin');

    expect(await File(decrypted).length(), await File(largeFile).length());
    expect(await File(decrypted).readAsBytes(),
        equals(await File(largeFile).readAsBytes()));
  });

  test('a pre-cancelled token stops encryption before it starts', () async {
    final token = CancellationToken()..cancel();

    await expectLater(
        BackupEncryption.encryptFile(plainFile, encryptedFile, 'dolphin',
            cancellationToken: token),
        throwsA(isA<BackupCancelledException>()));
    expect(await File(encryptedFile).exists(), isFalse);
  });
}
