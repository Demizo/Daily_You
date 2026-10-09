// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/crypto_utils.dart';

class SecurityQuestionHelper {
  static bool get hasSecurityQuestion {
    final q = ConfigProvider.instance.get(Settings.securityQuestion);
    final a = ConfigProvider.instance.get(Settings.securityAnswerHash);
    return q.trim().isNotEmpty && a.isNotEmpty;
  }

  static String get question =>
      ConfigProvider.instance.get(Settings.securityQuestion);

  static String _normalize(String input) =>
      input.trim().toLowerCase();

  static String _hash(String answer) {
    return sha256.convert(utf8.encode(_normalize(answer))).toString();
  }

  static Future<void> setSecurityQuestion(
      String question, String answer) async {
    await ConfigProvider.instance
        .set(Settings.securityQuestion, question.trim());
    await ConfigProvider.instance
        .set(Settings.securityAnswerHash, _hash(answer));
  }

  static Future<void> clearSecurityQuestion() async {
    await ConfigProvider.instance.set(Settings.securityQuestion, '');
    await ConfigProvider.instance.set(Settings.securityAnswerHash, '');
  }

  static bool validateAnswer(String answer) {
    final storedHash =
        ConfigProvider.instance.get(Settings.securityAnswerHash);
    if (storedHash.isEmpty) return false;
    final currentHash = _hash(answer);
    return constantTimeEquals(
        utf8.encode(storedHash), utf8.encode(currentHash));
  }

  static Future<void> resetAppLock() async {
    await ConfigProvider.instance.set(Settings.requirePassword, false);
    await ConfigProvider.instance.set(Settings.passwordHash, '');
    await ConfigProvider.instance.set(Settings.passwordIsPin, false);
    await clearSecurityQuestion();
  }
}
