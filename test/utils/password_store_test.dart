import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('AppPasswordStore', () {
    const store = AppPasswordStore();

    test('a saved password validates', () async {
      await store.save('dolphin');
      expect(await store.validate('dolphin'), isTrue);
    });

    test('the wrong password does not validate', () async {
      await store.save('dolphin');
      expect(await store.validate('wrong'), isFalse);
    });

    test('no password is set validates nothing', () async {
      expect(await store.validate('anything'), isFalse);
    });

    test('save records whether the password is numeric', () async {
      await store.save('1234');
      expect(store.isPin, isTrue);

      await store.save('not-numeric');
      expect(store.isPin, isFalse);
    });

    test('a saved hash uses the standard argon2 PHC string format', () async {
      await store.save('dolphin');
      expect(ConfigProvider.instance.get(Settings.passwordHash),
          startsWith(r'$argon2id$v=19$m='));
    });

    test('a legacy sha-256 hash validates once and is rehashed', () async {
      final legacyHash = sha256.convert(utf8.encode('dolphin')).toString();
      await ConfigProvider.instance.set(Settings.passwordHash, legacyHash);

      expect(await store.validate('dolphin'), isTrue);

      final rehashed = ConfigProvider.instance.get(Settings.passwordHash);
      expect(rehashed, isNot(legacyHash));
      expect(rehashed, startsWith(r'$argon2id$'));

      expect(await store.validate('dolphin'), isTrue);
    });

    test('a wrong password against a legacy hash does not validate or rehash',
        () async {
      final legacyHash = sha256.convert(utf8.encode('dolphin')).toString();
      await ConfigProvider.instance.set(Settings.passwordHash, legacyHash);

      expect(await store.validate('wrong'), isFalse);
      expect(ConfigProvider.instance.get(Settings.passwordHash), legacyHash);
    });

    test('a PHC hash written with different params than this app uses still '
        'validates', () async {
      const memoryKiB = 8192;
      const iterations = 3;
      const parallelism = 2;
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));

      final generator = Argon2BytesGenerator()
        ..init(Argon2Parameters(
          Argon2Parameters.ARGON2_id,
          salt,
          desiredKeyLength: 32,
          iterations: iterations,
          memory: memoryKiB,
          lanes: parallelism,
        ));
      final hash = Uint8List(32);
      generator.deriveKey(utf8.encode('dolphin'), 0, hash, 0);

      final saltB64 = base64Encode(salt).replaceAll('=', '');
      final hashB64 = base64Encode(hash).replaceAll('=', '');
      final foreignHash = '\$argon2id\$v=19\$m=$memoryKiB,t=$iterations,'
          'p=$parallelism\$$saltB64\$$hashB64';

      await ConfigProvider.instance.set(Settings.passwordHash, foreignHash);

      expect(await store.validate('dolphin'), isTrue);
      expect(await store.validate('wrong'), isFalse);
    });
  });

  group('BackupPasswordStore', () {
    const store = BackupPasswordStore();

    test('a saved password validates', () async {
      await store.save('dolphin');
      expect(await store.validate('dolphin'), isTrue);
    });

    test('the wrong password does not validate', () async {
      await store.save('dolphin');
      expect(await store.validate('wrong'), isFalse);
    });

    test('isEnabled requires both the toggle and a saved password', () async {
      expect(BackupPasswordStore.isEnabled, isFalse);

      await store.save('dolphin');
      expect(BackupPasswordStore.isEnabled, isFalse);

      await ConfigProvider.instance.set(Settings.backupPasswordEnabled, true);
      expect(BackupPasswordStore.isEnabled, isTrue);
    });
  });
}
