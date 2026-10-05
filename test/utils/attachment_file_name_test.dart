// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:daily_you/utils/attachment_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizedStem', () {
    test('keeps an ordinary name as it is', () {
      expect(sanitizedStem('Holiday photo (2).JPG'), 'Holiday photo (2)');
    });

    test('has no stem for a missing or empty name', () {
      expect(sanitizedStem(null), isNull);
      expect(sanitizedStem(''), isNull);
      expect(sanitizedStem('...'), isNull);
    });

    test('replaces characters that file systems and providers reject', () {
      expect(sanitizedStem('a"b*c:d<e>f?g\\h|i.jpg'), 'a_b_c_d_e_f_g_h_i');
      expect(sanitizedStem('line\nbreak\u0000.jpg'), 'line_break_');
    });

    test('keeps only the last path segment', () {
      expect(sanitizedStem('albums/2026/trip.mp3'), 'trip');
    });

    test('drops leading and trailing dots and spaces', () {
      expect(sanitizedStem('  ..hidden.. .jpg'), 'hidden');
      expect(sanitizedStem('clip. .mp4'), 'clip');
    });

    test('prefixes names Windows reserves for devices', () {
      expect(sanitizedStem('CON.mp3'), '_CON');
      expect(sanitizedStem('lpt3.mp3'), '_lpt3');
      expect(sanitizedStem('console.mp3'), 'console');
    });

    test('limits the length in bytes without splitting a character', () {
      final ascii = sanitizedStem('${'x' * 300}.mp3')!;
      final cjk = sanitizedStem('${'音' * 100}.mp3')!;
      final emoji = sanitizedStem('${'😀' * 100}.mp3')!;

      expect(ascii, 'x' * 100);
      expect(utf8.encode(cjk), hasLength(99));
      expect(utf8.encode(emoji), hasLength(100));
      expect(cjk.runes.every((rune) => rune == 0x97F3), isTrue);
      expect(emoji.runes.every((rune) => rune == 0x1F600), isTrue);
    });
  });

  group('sanitizedExtension', () {
    test('keeps the given extension including its case', () {
      expect(sanitizedExtension('photo.JPG', '.jpg'), '.JPG');
    });

    test('falls back when there is no usable extension', () {
      expect(sanitizedExtension(null, '.m4a'), '.m4a');
      expect(sanitizedExtension('recording', '.m4a'), '.m4a');
      expect(sanitizedExtension('recording.', '.m4a'), '.m4a');
      expect(sanitizedExtension('recording. ', '.m4a'), '.m4a');
    });

    test('replaces rejected characters and limits the length', () {
      expect(sanitizedExtension('clip.mp?', '.mp4'), '.mp_');
      expect(sanitizedExtension('clip.${'a' * 40}', '.mp4'), '.${'a' * 16}');
    });
  });
}
