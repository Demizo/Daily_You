// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:typed_data';

import 'package:daily_you/utils/audio_import_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioImportHelper (F20)', () {
    test('computes deterministic SHA-256 hash for deduplication', () {
      final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes3 = Uint8List.fromList([5, 4, 3, 2, 1]);

      final hash1 = AudioImportHelper.computeHash(bytes1);
      final hash2 = AudioImportHelper.computeHash(bytes2);
      final hash3 = AudioImportHelper.computeHash(bytes3);

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hash3)));
    });

    test('creates EntrySong with extracted title and artist from file name', () {
      final bytes = Uint8List.fromList([10, 20, 30, 40]);
      final song = AudioImportHelper.createSongFromBytes(
        fileName: 'Coldplay - Yellow.mp3',
        bytes: bytes,
      );

      expect(song.title, 'Yellow');
      expect(song.artist, 'Coldplay');
      expect(song.url, startsWith('file://audio_'));
      expect(song.previewStartMs, 0);
      expect(song.previewEndMs, 30000);
      expect(song.videoId, startsWith('loc_'));
    });

    test('handles file names without separator', () {
      final bytes = Uint8List.fromList([50, 60, 70]);
      final song = AudioImportHelper.createSongFromBytes(
        fileName: 'Recording_Voice01.m4a',
        bytes: bytes,
      );

      expect(song.title, 'Recording_Voice01');
      expect(song.artist, 'Local Audio');
    });
  });
}
