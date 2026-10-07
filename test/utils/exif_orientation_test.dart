import 'dart:typed_data';

import 'package:daily_you/utils/exif_orientation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List jpegWithRedTopLeft(int orientation) {
  final source = img.Image(width: 40, height: 20);
  img.fill(source, color: img.ColorRgb8(255, 255, 255));
  img.fillRect(source,
      x1: 0, y1: 0, x2: 10, y2: 10, color: img.ColorRgb8(255, 0, 0));
  source.exif.imageIfd.orientation = orientation;
  return img.encodeJpg(source, quality: 100);
}

String redCorner(img.Image image) {
  bool red(int x, int y) {
    final pixel = image.getPixel(x, y);
    return pixel.r > 200 && pixel.g < 80;
  }

  final right = image.width - 1;
  final bottom = image.height - 1;
  if (red(0, 0)) return 'topLeft';
  if (red(right, 0)) return 'topRight';
  if (red(0, bottom)) return 'bottomLeft';
  if (red(right, bottom)) return 'bottomRight';
  return 'none';
}

void main() {
  test('read returns the orientation tag', () {
    expect(ExifOrientation.read(jpegWithRedTopLeft(5)), 5);
  });

  test('isMirrored is true only for orientations 2, 4, 5 and 7', () {
    expect(
        [for (var value = 1; value <= 8; value++) value]
            .where(ExifOrientation.isMirrored),
        [2, 4, 5, 7]);
    expect(ExifOrientation.isMirrored(null), isFalse);
  });

  test('bake matches the image package baking for every orientation', () {
    for (var orientation = 1; orientation <= 8; orientation++) {
      final withTag = jpegWithRedTopLeft(orientation);
      final unrotated = img.decodeJpg(withTag)!
        ..exif.imageIfd.orientation = orientation;
      final expected = img.bakeOrientation(unrotated);

      // Plugin output: same pixels, tag dropped.
      final withoutTag = img.encodeJpg(img.decodeJpg(withTag)!, quality: 100);
      final baked = img.decodeJpg(
          ExifOrientation.bake(withoutTag, orientation, quality: 100))!;

      expect(baked.width, expected.width, reason: 'orientation $orientation');
      expect(redCorner(baked), redCorner(expected),
          reason: 'orientation $orientation');
      expect(baked.exif.imageIfd.orientation, anyOf(isNull, 1));
    }
  });
}
