// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/utils/youtube_url_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YouTubeUrlParser', () {
    test('extracts videoId from music.youtube.com with tracking params', () {
      const url =
          'https://music.youtube.com/watch?v=dQw4w9WgXcQ&si=tracking123&feature=share';
      final id = YouTubeUrlParser.extractVideoId(url);
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts videoId from standard youtube.com', () {
      const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final id = YouTubeUrlParser.extractVideoId(url);
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts videoId from youtu.be short link', () {
      const url = 'https://youtu.be/dQw4w9WgXcQ?si=abc';
      final id = YouTubeUrlParser.extractVideoId(url);
      expect(id, 'dQw4w9WgXcQ');
    });

    test('extracts videoId from shared intent text containing link', () {
      const text =
          'Hey check out this track: https://music.youtube.com/watch?v=9bZkp7q19f0 on YouTube Music';
      final id = YouTubeUrlParser.extractVideoId(text);
      expect(id, '9bZkp7q19f0');
    });

    test('normalizes URL dropping tracking params', () {
      final normalized = YouTubeUrlParser.normalizeUrl('dQw4w9WgXcQ');
      expect(normalized, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    });

    test('generates music URL and fallback thumbnail URL', () {
      expect(
        YouTubeUrlParser.musicUrl('dQw4w9WgXcQ'),
        'https://music.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(
        YouTubeUrlParser.fallbackThumbnailUrl('dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
    });

    test('returns null for invalid inputs', () {
      expect(YouTubeUrlParser.extractVideoId(''), isNull);
      expect(YouTubeUrlParser.extractVideoId('https://google.com'), isNull);
      expect(YouTubeUrlParser.extractVideoId('not a url at all'), isNull);
    });
  });
}
