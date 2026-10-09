// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'package:daily_you/utils/media_type_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaTypeUtils (F16)', () {
    test('detects video extensions case-insensitively', () {
      expect(MediaTypeUtils.isVideo('clip.mp4'), isTrue);
      expect(MediaTypeUtils.isVideo('movie.MP4'), isTrue);
      expect(MediaTypeUtils.isVideo('video.mov'), isTrue);
      expect(MediaTypeUtils.isVideo('record.mkv'), isTrue);
      expect(MediaTypeUtils.isVideo('stream.webm'), isTrue);
    });

    test('rejects non-video image extensions', () {
      expect(MediaTypeUtils.isVideo('photo.jpg'), isFalse);
      expect(MediaTypeUtils.isVideo('image.png'), isFalse);
      expect(MediaTypeUtils.isVideo('animation.gif'), isFalse);
      expect(MediaTypeUtils.isVideo('picture.webp'), isFalse);
      expect(MediaTypeUtils.isVideo(''), isFalse);
    });
  });
}
