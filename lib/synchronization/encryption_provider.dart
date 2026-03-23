import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionProvider {
  final String _key;
  final _algorithm = Xchacha20.poly1305Aead();

  EncryptionProvider(this._key);

  Future<List<int>> encrypt(String plainText) async {
    final secretKey = SecretKey(utf8.encode(_key));

    final secretBox = await _algorithm.encrypt(utf8.encode(plainText), secretKey: secretKey);

    return secretBox.concatenation();
  }

  Future<String> decrypt(List<int> combinedData) async {
    final secretKey = SecretKey(utf8.encode(_key));

    final secretBox = SecretBox.fromConcatenation(
      combinedData,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );

    final clearTextBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(clearTextBytes);
  }
}