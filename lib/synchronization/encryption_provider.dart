import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class EncryptionProvider {
  final String _key;
  final _algorithm = Xchacha20.poly1305Aead();

  EncryptionProvider(this._key);

  static String generateEncryptionKey() {
    return base64Url.encode(SecretKeyData.random(length: 32).bytes);
  }

  Future<List<int>> encrypt(String plainText) async {
    final secretKey = SecretKey(base64Url.decode(_key));

    final secretBox = await _algorithm.encrypt(utf8.encode(plainText), secretKey: secretKey);

    return secretBox.concatenation();
  }

  Future<List<int>> encryptBytes(List<int> plainBytes) async {
    final secretKey = SecretKey(base64Url.decode(_key));

    final secretBox = await _algorithm.encrypt(plainBytes, secretKey: secretKey);

    return secretBox.concatenation();
  }

  Future<String> decrypt(List<int> combinedData) async {
    final secretKey = SecretKey(base64Url.decode(_key));

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

  Future<List<int>> decryptBytes(List<int> combinedData) async {
    final secretKey = SecretKey(base64Url.decode(_key));

    final secretBox = SecretBox.fromConcatenation(
      combinedData,
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );

    final clearTextBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return clearTextBytes;
  }
}