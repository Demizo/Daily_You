// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:share_receiver/share_receiver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SharePayload.fromMap', () {
    test('returns null when nothing is pending', () {
      expect(SharePayload.fromMap(null), isNull);
    });

    test('returns null for a share with neither text nor media', () {
      expect(SharePayload.fromMap({'text': null, 'imagePaths': <Object?>[]}),
          isNull);
    });

    test('returns null when no shared file was a supported kind', () {
      expect(
          SharePayload.fromMap({
            'text': null,
            'imagePaths': <Object?>[],
            'videoPaths': <Object?>[],
            'audioPaths': <Object?>[],
          }),
          isNull);
    });

    test('keeps the supported kinds of a mixed share', () {
      final result = SharePayload.fromMap({
        'text': null,
        'imagePaths': ['a.jpg'],
        'videoPaths': <Object?>[],
        'audioPaths': ['a.m4a'],
      });

      expect(result!.hasMedia, isTrue);
      expect(result.imagePaths, ['a.jpg']);
      expect(result.videoPaths, isEmpty);
      expect(result.audioPaths, ['a.m4a']);
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

    test('keeps shared video and audio separate from images', () {
      final result = SharePayload.fromMap({
        'imagePaths': ['a.jpg'],
        'videoPaths': ['a.mp4'],
        'audioPaths': ['a.m4a'],
      });

      expect(result!.imagePaths, ['a.jpg']);
      expect(result.videoPaths, ['a.mp4']);
      expect(result.audioPaths, ['a.m4a']);
    });

    test('uses text alone when there is no image', () {
      final result = SharePayload.fromMap({'text': 'hello'});

      expect(result!.text, 'hello');
      expect(result.imagePaths, isEmpty);
    });
  });

  test('deleteMedia removes the cached files and their directory', () {
    final root = Directory.systemTemp.createTempSync('share_test');
    addTearDown(() => root.deleteSync(recursive: true));
    final directory = Directory('${root.path}/share')..createSync();
    final existing = File('${directory.path}/a.jpg')..writeAsBytesSync([1]);
    final payload = SharePayload(
        imagePaths: [existing.path, '${directory.path}/missing.jpg']);

    payload.deleteMedia();

    expect(existing.existsSync(), isFalse);
    expect(directory.existsSync(), isFalse);
  });
}
