import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:daily_you/config_provider.dart';
import 'package:pointycastle/export.dart';

abstract class PasswordStore {
  const PasswordStore();

  bool get isPin => false;

  Future<bool> validate(String password);

  Future<void> save(String password);
}

class AppPasswordStore extends PasswordStore {
  const AppPasswordStore();

  @override
  bool get isPin => ConfigProvider.instance.get(Settings.passwordIsPin);

  @override
  Future<bool> validate(String password) async {
    final stored = ConfigProvider.instance.get(Settings.passwordHash);
    if (stored.isEmpty) return false;

    final decoded = _Argon2Phc.tryDecode(stored);
    if (decoded != null) return decoded.verify(password);

    final legacyHash = sha256.convert(utf8.encode(password)).toString();
    if (!_constantTimeEquals(utf8.encode(stored), utf8.encode(legacyHash))) {
      return false;
    }
    await save(password);
    return true;
  }

  @override
  Future<void> save(String password) async {
    await ConfigProvider.instance
        .set(Settings.passwordHash, _Argon2Phc.hashPassword(password));
    await ConfigProvider.instance
        .set(Settings.passwordIsPin, RegExp(r'^\d+$').hasMatch(password));
  }
}

class BackupPasswordStore extends PasswordStore {
  const BackupPasswordStore();

  static String get password =>
      ConfigProvider.instance.get(Settings.backupPassword);

  static bool get isEnabled =>
      ConfigProvider.instance.get(Settings.backupPasswordEnabled) &&
      password.isNotEmpty;

  @override
  Future<bool> validate(String password) async => _constantTimeEquals(
      utf8.encode(BackupPasswordStore.password), utf8.encode(password));

  @override
  Future<void> save(String password) async =>
      ConfigProvider.instance.set(Settings.backupPassword, password);
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}

class _Argon2Phc {
  static const _memoryKiB = 19456;
  static const _iterations = 2;
  static const _parallelism = 1;
  static const _hashLength = 32;
  static const _saltLength = 16;
  static const _version = 19;

  static final _pattern = RegExp(
      r'^\$argon2id\$v=(\d+)\$m=(\d+),t=(\d+),p=(\d+)\$([^$]+)\$([^$]+)$');

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final Uint8List salt;
  final Uint8List hash;

  const _Argon2Phc({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.salt,
    required this.hash,
  });

  static String hashPassword(String password) {
    final salt = _randomBytes(_saltLength);
    final hash = _derive(
      password: password,
      salt: salt,
      memoryKiB: _memoryKiB,
      iterations: _iterations,
      parallelism: _parallelism,
      keyLength: _hashLength,
    );
    return '\$argon2id\$v=$_version\$m=$_memoryKiB,t=$_iterations,'
        'p=$_parallelism\$${_encodeUnpadded(salt)}\$${_encodeUnpadded(hash)}';
  }

  static _Argon2Phc? tryDecode(String stored) {
    final match = _pattern.firstMatch(stored);
    if (match == null) return null;
    try {
      return _Argon2Phc(
        memoryKiB: int.parse(match.group(2)!),
        iterations: int.parse(match.group(3)!),
        parallelism: int.parse(match.group(4)!),
        salt: _decodeUnpadded(match.group(5)!),
        hash: _decodeUnpadded(match.group(6)!),
      );
    } catch (_) {
      return null;
    }
  }

  bool verify(String password) {
    final actual = _derive(
      password: password,
      salt: salt,
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      keyLength: hash.length,
    );
    return _constantTimeEquals(actual, hash);
  }

  static Uint8List _derive({
    required String password,
    required Uint8List salt,
    required int memoryKiB,
    required int iterations,
    required int parallelism,
    required int keyLength,
  }) {
    final generator = Argon2BytesGenerator()
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        desiredKeyLength: keyLength,
        iterations: iterations,
        memory: memoryKiB,
        lanes: parallelism,
      ));
    final output = Uint8List(keyLength);
    generator.deriveKey(
        Uint8List.fromList(utf8.encode(password)), 0, output, 0);
    return output;
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => random.nextInt(256)));
  }

  static String _encodeUnpadded(Uint8List bytes) =>
      base64Encode(bytes).replaceAll('=', '');

  static Uint8List _decodeUnpadded(String value) =>
      base64Decode(value.padRight((value.length + 3) ~/ 4 * 4, '='));
}
