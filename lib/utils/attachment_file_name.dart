// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';

import 'package:path/path.dart' as p;

const int _maxStemBytes = 100;
const int _maxExtensionBytes = 16;

final RegExp _forbiddenCharacters = RegExp(r'[\x00-\x1F\x7F"*/:<>?\\|]');
final RegExp _outerDotsAndSpaces = RegExp(r'^[.\s]+|[.\s]+$');
final RegExp _reservedDeviceName =
    RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$', caseSensitive: false);

String? sanitizedStem(String? fileName) {
  if (fileName == null) return null;
  var stem = _truncateToBytes(
      _clean(p.basenameWithoutExtension(fileName)), _maxStemBytes);
  stem = stem.replaceAll(_outerDotsAndSpaces, '');
  if (stem.isEmpty) return null;
  return _reservedDeviceName.hasMatch(stem) ? '_$stem' : stem;
}

String sanitizedExtension(String? fileName, String fallback) {
  if (fileName == null) return fallback;
  final extension = _truncateToBytes(
      _clean(p.extension(fileName)).replaceAll(_outerDotsAndSpaces, ''),
      _maxExtensionBytes);
  return extension.isEmpty ? fallback : '.$extension';
}

String _clean(String value) => value.replaceAll(_forbiddenCharacters, '_');

String _truncateToBytes(String value, int maxBytes) {
  var bytes = 0;
  final kept = StringBuffer();
  for (final rune in value.runes) {
    final runeBytes = utf8.encode(String.fromCharCode(rune)).length;
    if (bytes + runeBytes > maxBytes) break;
    bytes += runeBytes;
    kept.writeCharCode(rune);
  }
  return kept.toString();
}
