// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

class BitapPattern {
  BitapPattern(String pattern, this.maxErrors)
      : length = pattern.length,
        _latinMasks = Int64List(256),
        _otherMasks = {},
        _state = Int64List(maxErrors + 1),
        _stateBeforePrevious = Int64List(maxErrors + 1) {
    for (var index = 0; index < pattern.length; index++) {
      final unit = pattern.codeUnitAt(index);
      if (unit < 256) {
        _latinMasks[unit] |= 1 << index;
      } else {
        _otherMasks[unit] = (_otherMasks[unit] ?? 0) | (1 << index);
      }
    }
  }

  final int length;
  final int maxErrors;
  final Int64List _latinMasks;
  final Map<int, int> _otherMasks;
  final Int64List _state;
  final Int64List _stateBeforePrevious;

  int errorsIn(String text, {int stopAtErrors = 0}) =>
      _scan(text, stopAtErrors, null);

  void forEachMatchEnd(
    String text,
    void Function(int endIndex, int errors) onMatch,
  ) =>
      _scan(text, -1, onMatch);

  int _maskOf(int unit) {
    if (unit < 256) return _latinMasks[unit];
    return _otherMasks[unit] ?? 0;
  }

  int _scan(
    String text,
    int stopAtErrors,
    void Function(int endIndex, int errors)? onMatch,
  ) {
    final accept = 1 << (length - 1);
    final state = _state;
    final stateBeforePrevious = _stateBeforePrevious;
    for (var errors = 0; errors <= maxErrors; errors++) {
      state[errors] = (1 << errors) - 1;
      stateBeforePrevious[errors] = (1 << errors) - 1;
    }
    final noMatch = maxErrors + 1;
    var best = noMatch;
    var previousMask = 0;
    for (var index = 0; index < text.length; index++) {
      final mask = _maskOf(text.codeUnitAt(index));
      final swappable = (mask << 1) & previousMask;
      var previousOld = state[0];
      var previousNew = ((previousOld << 1) | 1) & mask;
      var previousBeforePrevious = stateBeforePrevious[0];
      stateBeforePrevious[0] = previousOld;
      state[0] = previousNew;
      for (var errors = 1; errors <= maxErrors; errors++) {
        final old = state[errors];
        final oldBeforePrevious = stateBeforePrevious[errors];
        final next = (((old << 1) | 1) & mask) |
            previousOld |
            ((previousOld << 1) | 1) |
            ((previousNew << 1) | 1) |
            (swappable & ((previousBeforePrevious << 2) | 2));
        state[errors] = next;
        stateBeforePrevious[errors] = old;
        previousOld = old;
        previousNew = next;
        previousBeforePrevious = oldBeforePrevious;
      }
      previousMask = mask;

      final limit = onMatch == null ? best : noMatch;
      var errorsHere = noMatch;
      for (var errors = 0; errors < limit; errors++) {
        if (state[errors] & accept != 0) {
          errorsHere = errors;
          break;
        }
      }
      if (errorsHere < best) {
        best = errorsHere;
        if (best <= stopAtErrors) return best;
      }
      if (onMatch != null && errorsHere < noMatch) onMatch(index, errorsHere);
    }
    return best;
  }
}
