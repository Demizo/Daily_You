import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The Android compression plugin rotates pixels by the EXIF angle but ignores
/// the mirror half of orientations.
///
/// To compensate we bake it into the thumbnail
class ExifOrientation {
  static const _mirrored = {2, 4, 5, 7};

  static int? read(Uint8List jpegBytes) {
    try {
      return img.decodeJpgExif(jpegBytes)?.imageIfd.orientation;
    } catch (_) {
      return null;
    }
  }

  static bool isMirrored(int? orientation) => _mirrored.contains(orientation);

  /// Returns [pixelsAsStored] with [orientation] applied to the pixels and no
  /// orientation tag left behind.
  static Uint8List bake(Uint8List pixelsAsStored, int orientation,
      {required int quality}) {
    final decoded = img.decodeJpg(pixelsAsStored);
    if (decoded == null) return pixelsAsStored;
    decoded.exif.imageIfd.orientation = orientation;
    return img.encodeJpg(img.bakeOrientation(decoded), quality: quality);
  }
}
