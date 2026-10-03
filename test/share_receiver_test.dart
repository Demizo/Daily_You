import 'dart:io';

import 'package:share_receiver/share_receiver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharePayload.fromMap', () {
    test('returns null when nothing is pending', () {
      expect(SharePayload.fromMap(null), isNull);
    });

    test('returns null for a share with neither text nor images', () {
      expect(SharePayload.fromMap({'text': null, 'imagePaths': <Object?>[]}),
          isNull);
    });

    test('builds a payload for an image-only share', () {
      final result = SharePayload.fromMap({
        'text': null,
        'imagePaths': ['a.jpg'],
      });

      expect(result!.text, isNull);
      expect(result.imagePaths, ['a.jpg']);
    });

    test('combines text with shared images', () {
      final result = SharePayload.fromMap({
        'text': 'caption',
        'imagePaths': ['a.jpg', 'b.jpg'],
      });

      expect(result!.text, 'caption');
      expect(result.imagePaths, ['a.jpg', 'b.jpg']);
    });

    test('uses text alone when there is no image', () {
      final result = SharePayload.fromMap({'text': 'hello'});

      expect(result!.text, 'hello');
      expect(result.imagePaths, isEmpty);
    });
  });

  test('deleteImages removes the cached files and their directory', () {
    final root = Directory.systemTemp.createTempSync('share_test');
    addTearDown(() => root.deleteSync(recursive: true));
    final directory = Directory('${root.path}/share')..createSync();
    final existing = File('${directory.path}/a.jpg')..writeAsBytesSync([1]);
    final payload = SharePayload(
        imagePaths: [existing.path, '${directory.path}/missing.jpg']);

    payload.deleteImages();

    expect(existing.existsSync(), isFalse);
    expect(directory.existsSync(), isFalse);
  });
}
