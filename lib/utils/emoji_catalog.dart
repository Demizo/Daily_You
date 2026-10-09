// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/config_provider.dart';

class EmojiItem {
  final String emoji;
  final String name;
  final List<String> keywords;

  const EmojiItem({
    required this.emoji,
    required this.name,
    this.keywords = const [],
  });
}

class EmojiCatalog {
  static const List<EmojiItem> moodEmojis = [
    EmojiItem(emoji: '☺️', name: 'smiling face', keywords: ['happy', 'smile', 'blush', 'warm']),
    EmojiItem(emoji: '🙂', name: 'slightly smiling face', keywords: ['smile', 'content', 'okay', 'fine']),
    EmojiItem(emoji: '😐', name: 'neutral face', keywords: ['neutral', 'meh', 'blank', 'ok']),
    EmojiItem(emoji: '😕', name: 'confused face', keywords: ['confused', 'sad', 'unsure', 'bothered']),
    EmojiItem(emoji: '😔', name: 'pensive face', keywords: ['sad', 'down', 'depressed', 'gloomy']),
    EmojiItem(emoji: '😀', name: 'grinning face', keywords: ['happy', 'grin', 'cheerful']),
    EmojiItem(emoji: '😃', name: 'grinning face with big eyes', keywords: ['happy', 'joy', 'excited']),
    EmojiItem(emoji: '😄', name: 'grinning face with smiling eyes', keywords: ['laugh', 'happy']),
    EmojiItem(emoji: '😁', name: 'beaming face', keywords: ['beam', 'smile', 'proud']),
    EmojiItem(emoji: '😆', name: 'grinning squinting face', keywords: ['laugh', 'fun', 'amused']),
    EmojiItem(emoji: '🥹', name: 'face holding back tears', keywords: ['emotional', 'gratitude', 'touched']),
    EmojiItem(emoji: '😅', name: 'grinning face with sweat', keywords: ['relief', 'awkward', 'whew']),
    EmojiItem(emoji: '😂', name: 'face with tears of joy', keywords: ['laughing', 'lol', 'funny']),
    EmojiItem(emoji: '🤣', name: 'rolling on the floor laughing', keywords: ['rofl', 'hilarious']),
    EmojiItem(emoji: '😇', name: 'smiling face with halo', keywords: ['angel', 'innocent', 'good']),
    EmojiItem(emoji: '🥰', name: 'smiling face with hearts', keywords: ['love', 'crush', 'blessed']),
    EmojiItem(emoji: '😍', name: 'heart eyes', keywords: ['love', 'adore', 'heart']),
    EmojiItem(emoji: '🤩', name: 'star-struck', keywords: ['wow', 'amazing', 'fan', 'star']),
    EmojiItem(emoji: '😘', name: 'face blowing a kiss', keywords: ['kiss', 'love']),
    EmojiItem(emoji: '😋', name: 'face savoring food', keywords: ['yum', 'delicious', 'food']),
    EmojiItem(emoji: '😛', name: 'face with tongue', keywords: ['silly', 'tongue', 'playful']),
    EmojiItem(emoji: '😜', name: 'winking face with tongue', keywords: ['winking', 'joke', 'crazy']),
    EmojiItem(emoji: '🤪', name: 'zany face', keywords: ['wild', 'party', 'funny', 'zany']),
    EmojiItem(emoji: '😎', name: 'smiling face with sunglasses', keywords: ['cool', 'chill', 'sunglasses']),
    EmojiItem(emoji: '🥳', name: 'partying face', keywords: ['party', 'celebrate', 'birthday']),
    EmojiItem(emoji: '😏', name: 'smirking face', keywords: ['smirk', 'flirt', 'clever']),
    EmojiItem(emoji: '😒', name: 'unamused face', keywords: ['annoyed', 'meh', 'unimpressed']),
    EmojiItem(emoji: '😞', name: 'disappointed face', keywords: ['sad', 'disappointed']),
    EmojiItem(emoji: '😟', name: 'worried face', keywords: ['worried', 'nervous']),
    EmojiItem(emoji: '😤', name: 'face with steam from nose', keywords: ['frustrated', 'proud', 'triumph']),
    EmojiItem(emoji: '😡', name: 'enraged face', keywords: ['angry', 'mad', 'furious']),
    EmojiItem(emoji: '😠', name: 'angry face', keywords: ['mad', 'annoyed']),
    EmojiItem(emoji: '🤬', name: 'face with symbols on mouth', keywords: ['swearing', 'rage', 'curse']),
    EmojiItem(emoji: '🤯', name: 'exploding head', keywords: ['mindblown', 'shocked', 'crazy']),
    EmojiItem(emoji: '😳', name: 'flushed face', keywords: ['embarrassed', 'blushing', 'surprised']),
    EmojiItem(emoji: '🥵', name: 'hot face', keywords: ['hot', 'heat', 'sweating']),
    EmojiItem(emoji: '🥶', name: 'cold face', keywords: ['cold', 'freezing', 'ice']),
    EmojiItem(emoji: '😱', name: 'face screaming in fear', keywords: ['shock', 'scream', 'scared']),
    EmojiItem(emoji: '😨', name: 'fearful face', keywords: ['scared', 'fear']),
    EmojiItem(emoji: '😰', name: 'anxious face with sweat', keywords: ['anxious', 'nervous', 'stress']),
    EmojiItem(emoji: '😥', name: 'sad but relieved face', keywords: ['relieved', 'whew', 'phew']),
    EmojiItem(emoji: '😢', name: 'crying face', keywords: ['cry', 'tear', 'sad']),
    EmojiItem(emoji: '😭', name: 'loudly crying face', keywords: ['sobbing', 'bawling', 'grief']),
    EmojiItem(emoji: '🥱', name: 'yawning face', keywords: ['tired', 'sleepy', 'bored']),
    EmojiItem(emoji: '😴', name: 'sleeping face', keywords: ['sleep', 'zzz', 'night']),
    EmojiItem(emoji: '🤤', name: 'drooling face', keywords: ['drool', 'craving']),
    EmojiItem(emoji: '😷', name: 'face with medical mask', keywords: ['sick', 'mask', 'ill']),
    EmojiItem(emoji: '🤒', name: 'face with thermometer', keywords: ['fever', 'sick']),
    EmojiItem(emoji: '🤕', name: 'face with head-bandage', keywords: ['hurt', 'injured']),
    EmojiItem(emoji: '🤢', name: 'nauseated face', keywords: ['nausea', 'gross', 'sick']),
    EmojiItem(emoji: '🤮', name: 'face vomiting', keywords: ['vomit', 'disgusted']),
    EmojiItem(emoji: '🤧', name: 'sneezing face', keywords: ['sneeze', 'cold']),
    EmojiItem(emoji: '🥴', name: 'woozy face', keywords: ['dizzy', 'drunk', 'woozy']),
    EmojiItem(emoji: '😵', name: 'face with crossed-out eyes', keywords: ['dizzy', 'dead', 'ko']),
    EmojiItem(emoji: '🤔', name: 'thinking face', keywords: ['think', 'wonder', 'hmm']),
    EmojiItem(emoji: '🫠', name: 'melting face', keywords: ['melt', 'hot', 'sarcasm']),
    EmojiItem(emoji: '🤫', name: 'shushing face', keywords: ['quiet', 'secret', 'shh']),
    EmojiItem(emoji: '🫡', name: 'saluting face', keywords: ['salute', 'respect', 'yes sir']),
    EmojiItem(emoji: '🤗', name: 'smiling face with open hands', keywords: ['hug', 'warm', 'welcome']),
  ];

  static List<String> getRecents() {
    final raw = ConfigProvider.instance.get(Settings.recentEmojis);
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static Future<void> addRecent(String emoji) async {
    final current = getRecents();
    current.remove(emoji);
    current.insert(0, emoji);
    if (current.length > 20) {
      current.removeRange(20, current.length);
    }
    await ConfigProvider.instance.set(Settings.recentEmojis, current.join(','));
  }

  static List<EmojiItem> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return moodEmojis;
    return moodEmojis.where((item) {
      if (item.name.toLowerCase().contains(clean)) return true;
      if (item.keywords.any((k) => k.toLowerCase().contains(clean))) return true;
      if (item.emoji == clean) return true;
      return false;
    }).toList();
  }
}
