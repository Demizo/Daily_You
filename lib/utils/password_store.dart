import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:daily_you/config_provider.dart';

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
    final storedHash = ConfigProvider.instance.get(Settings.passwordHash);
    if (storedHash.isEmpty) return false;
    return storedHash == _hash(password);
  }

  @override
  Future<void> save(String password) async {
    await ConfigProvider.instance.set(Settings.passwordHash, _hash(password));
    await ConfigProvider.instance
        .set(Settings.passwordIsPin, RegExp(r'^\d+$').hasMatch(password));
  }

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}
