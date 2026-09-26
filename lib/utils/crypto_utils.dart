import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

const defaultArgon2MemoryKiB = 19456;
const defaultArgon2Iterations = 2;
const defaultArgon2Parallelism = 1;
const defaultArgon2KeyLength = 32;

Uint8List deriveArgon2idKey({
  required String password,
  required Uint8List salt,
  int memoryKiB = defaultArgon2MemoryKiB,
  int iterations = defaultArgon2Iterations,
  int parallelism = defaultArgon2Parallelism,
  int keyLength = defaultArgon2KeyLength,
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
  generator.deriveKey(Uint8List.fromList(utf8.encode(password)), 0, output, 0);
  return output;
}

Uint8List secureRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)));
}

bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
