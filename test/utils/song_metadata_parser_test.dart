// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/utils/song_metadata_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongMetadataParser', () {
    test('parses - Topic artist correctly without altering title', () {
      final parsed = SongMetadataParser.parse(
        rawTitle: 'Starboy',
        authorName: 'The Weeknd - Topic',
      );
      expect(parsed.title, 'Starboy');
      expect(parsed.artist, 'The Weeknd');
    });

    test('parses Artist - Title and strips (Official Video) noise', () {
      final parsed = SongMetadataParser.parse(
        rawTitle: 'Rick Astley - Never Gonna Give You Up (Official Music Video)',
        authorName: 'RickAstleyVEVO',
      );
      expect(parsed.title, 'Never Gonna Give You Up');
      expect(parsed.artist, 'Rick Astley');
    });

    test('strips [Lyrics], (Audio), (Visualizer) noise', () {
      final parsed = SongMetadataParser.parse(
        rawTitle: 'Queen - Bohemian Rhapsody [Lyrics]',
        authorName: 'Queen Official',
      );
      expect(parsed.title, 'Bohemian Rhapsody');
      expect(parsed.artist, 'Queen');

      final parsed2 = SongMetadataParser.parse(
        rawTitle: 'Coldplay - Yellow (Audio)',
        authorName: 'Coldplay',
      );
      expect(parsed2.title, 'Yellow');
      expect(parsed2.artist, 'Coldplay');
    });

    test('handles fallback when no dash separator is present', () {
      final parsed = SongMetadataParser.parse(
        rawTitle: 'Imagine (Official Video)',
        authorName: 'John Lennon',
      );
      expect(parsed.title, 'Imagine');
      expect(parsed.artist, 'John Lennon');
    });
  });
}
