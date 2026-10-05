// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:typed_data';

import 'package:daily_you/file_bytes_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uint8List bytes(int length) => Uint8List(length);

  test('keeps values within the limit', () {
    final cache = FileBytesCache(maxCacheSize: 10);

    cache.put('a', bytes(4));
    cache.put('b', bytes(4));

    expect(cache.get('a'), isNotNull);
    expect(cache.get('b'), isNotNull);
    expect(cache.currentSize, 8);
  });

  test('evicts the least recently used value to make room', () {
    final cache = FileBytesCache(maxCacheSize: 10);
    cache.put('a', bytes(4));
    cache.put('b', bytes(4));
    cache.get('a');

    cache.put('c', bytes(4));

    expect(cache.get('b'), isNull);
    expect(cache.get('a'), isNotNull);
    expect(cache.get('c'), isNotNull);
  });

  test('refuses a value over the limit and keeps what it has', () {
    final cache = FileBytesCache(maxCacheSize: 10);
    cache.put('a', bytes(4));

    cache.put('video', bytes(11));

    expect(cache.get('video'), isNull);
    expect(cache.get('a'), isNotNull);
    expect(cache.currentSize, 4);
  });

  test('drops a stale value when its replacement is over the limit', () {
    final cache = FileBytesCache(maxCacheSize: 10);
    cache.put('a', bytes(4));

    cache.put('a', bytes(11));

    expect(cache.get('a'), isNull);
    expect(cache.itemCount, 0);
    expect(cache.currentSize, 0);
  });
}
