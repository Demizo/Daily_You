// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/emoji_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/config_provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  useTemporaryConfig();

  group('EmojiCatalog & Recents (F12)', () {
    test('searches emojis by name and keyword', () {
      final happyResults = EmojiCatalog.search('happy');
      expect(happyResults, isNotEmpty);
      expect(happyResults.any((e) => e.emoji == '☺️'), isTrue);

      final sadResults = EmojiCatalog.search('sad');
      expect(sadResults, isNotEmpty);
      expect(sadResults.any((e) => e.emoji == '😔'), isTrue);

      final directEmoji = EmojiCatalog.search('😎');
      expect(directEmoji.length, 1);
      expect(directEmoji.first.emoji, '😎');
    });

    test('recents management adds to front and preserves uniqueness', () async {
      await ConfigProvider.instance.set(Settings.recentEmojis, '🙂,😐');
      expect(EmojiCatalog.getRecents(), ['🙂', '😐']);

      await EmojiCatalog.addRecent('🎉');
      expect(EmojiCatalog.getRecents().first, '🎉');
      expect(EmojiCatalog.getRecents().contains('🙂'), isTrue);

      // Re-adding existing moves to front without duplicating
      await EmojiCatalog.addRecent('😐');
      final updated = EmojiCatalog.getRecents();
      expect(updated.first, '😐');
      expect(updated.where((e) => e == '😐').length, 1);
    });
  });
}
