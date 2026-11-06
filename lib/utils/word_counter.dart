// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

const int _wordKind = 0;
const int _removedKind = 1;
const int _spaceKind = 2;

final Uint8List _asciiKinds = _buildAsciiKinds();

Uint8List _buildAsciiKinds() {
  final kinds = Uint8List(128);
  for (final unit in ",.:;[]{}()<>\$!?~'\"*/\\&%@#^-".codeUnits) {
    kinds[unit] = _removedKind;
  }
  for (var unit = 9; unit <= 13; unit++) {
    kinds[unit] = _spaceKind;
  }
  kinds[32] = _spaceKind;
  return kinds;
}

int countWords(String text) {
  final length = text.length;
  var count = 0;
  var inWord = false;
  for (var index = 0; index < length; index++) {
    final unit = text.codeUnitAt(index);
    if (unit > 127) return _countUnicodeWords(text);
    final kind = _asciiKinds[unit];
    if (kind == _spaceKind) {
      inWord = false;
    } else if (kind == _wordKind && !inWord) {
      inWord = true;
      count++;
    }
  }
  return count;
}

int _countUnicodeWords(String text) {
  if (_isBlank(text)) return 0;
  final length = text.length;
  var count = 0;
  var inWord = false;
  for (var index = 0; index < length; index++) {
    final unit = text.codeUnitAt(index);
    if (_isRemovedPunctuation(unit)) continue;
    if (_isIdeographic(unit)) {
      count++;
      inWord = false;
    } else if (_isWordUnit(unit)) {
      if (!inWord) {
        inWord = true;
        count++;
      }
    } else {
      inWord = false;
    }
  }
  return count;
}

bool _isBlank(String text) {
  final length = text.length;
  for (var index = 0; index < length; index++) {
    if (!_isTrimmedWhitespace(text.codeUnitAt(index))) return false;
  }
  return true;
}

bool _isTrimmedWhitespace(int unit) =>
    (unit >= 9 && unit <= 13) ||
    unit == 0x20 ||
    unit == 0x85 ||
    unit == 0xA0 ||
    unit == 0x1680 ||
    (unit >= 0x2000 && unit <= 0x200A) ||
    unit == 0x2028 ||
    unit == 0x2029 ||
    unit == 0x202F ||
    unit == 0x205F ||
    unit == 0x3000 ||
    unit == 0xFEFF;

bool _isRemovedPunctuation(int unit) {
  if (unit < 128) return _asciiKinds[unit] == _removedKind;
  return switch (unit) {
    0x3001 ||
    0x3002 ||
    0x300A ||
    0x300B ||
    0x3010 ||
    0x3011 ||
    0xFF01 ||
    0xFF08 ||
    0xFF09 ||
    0xFF0C ||
    0xFF1A ||
    0xFF1B ||
    0xFF1F ||
    0xFF5B ||
    0xFF5D ||
    0xFF5E ||
    0xFFE5 =>
      true,
    _ => false,
  };
}

bool _isIdeographic(int unit) =>
    (unit >= 0x1100 && unit <= 0x11FF) ||
    (unit >= 0x2E80 && unit <= 0x2FDF) ||
    (unit >= 0x3000 && unit <= 0x30FF) ||
    (unit >= 0x3130 && unit <= 0x319F) ||
    (unit >= 0x31F0 && unit <= 0x31FF) ||
    (unit >= 0x3300 && unit <= 0x4DBF) ||
    (unit >= 0x4E00 && unit <= 0x9FFF) ||
    (unit >= 0xA960 && unit <= 0xA97F) ||
    (unit >= 0xAC00 && unit <= 0xD7FF) ||
    (unit >= 0xF900 && unit <= 0xFAFF) ||
    (unit >= 0xFE30 && unit <= 0xFE4F);

bool _isWordUnit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    (unit >= 0xC0 && unit <= 0x2AF) ||
    (unit >= 0x370 && unit <= 0x6FF) ||
    (unit >= 0x750 && unit <= 0x77F) ||
    (unit >= 0x8A0 && unit <= 0xEFF) ||
    (unit >= 0x1000 && unit <= 0x1360) ||
    (unit >= 0x1362 && unit <= 0x137F) ||
    (unit >= 0x13A0 && unit <= 0x177F) ||
    (unit >= 0x1E00 && unit <= 0x1EFF) ||
    (unit >= 0xFB50 && unit <= 0xFDFF) ||
    (unit >= 0xFE70 && unit <= 0xFEFF);
