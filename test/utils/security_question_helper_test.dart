// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/security_question_helper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('SecurityQuestionHelper (F13)', () {
    test('initially has no security question', () {
      expect(SecurityQuestionHelper.hasSecurityQuestion, isFalse);
      expect(SecurityQuestionHelper.question, isEmpty);
    });

    test('sets and validates security question case-insensitively', () async {
      await SecurityQuestionHelper.setSecurityQuestion(
        'What was your first pet name?',
        'Buddy',
      );

      expect(SecurityQuestionHelper.hasSecurityQuestion, isTrue);
      expect(SecurityQuestionHelper.question,
          'What was your first pet name?');

      expect(SecurityQuestionHelper.validateAnswer('buddy'), isTrue);
      expect(SecurityQuestionHelper.validateAnswer('  BUDDY  '), isTrue);
      expect(SecurityQuestionHelper.validateAnswer('wrong'), isFalse);
    });

    test('resetAppLock clears password lock and security question', () async {
      await ConfigProvider.instance.set(Settings.requirePassword, true);
      await SecurityQuestionHelper.setSecurityQuestion('Question', 'Answer');

      expect(ConfigProvider.instance.get(Settings.requirePassword), isTrue);
      expect(SecurityQuestionHelper.hasSecurityQuestion, isTrue);

      await SecurityQuestionHelper.resetAppLock();

      expect(ConfigProvider.instance.get(Settings.requirePassword), isFalse);
      expect(SecurityQuestionHelper.hasSecurityQuestion, isFalse);
    });
  });
}
