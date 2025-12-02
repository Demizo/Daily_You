import 'dart:typed_data';

import 'package:flutter/material.dart';

class MemoryImageCache {
  final int maxCacheSize; // Maximum cache size in bytes
  int _currentSize = 0;

  final Map<String, MemoryImage> _cache = {};
  final List<String> _usageOrder = []; // To track least recently used keys

  MemoryImageCache({required this.maxCacheSize});

  MemoryImage? get(String key) {
    if (_cache.containsKey(key)) {
      // Update usage order to mark as recently used
      _usageOrder.remove(key);
      _usageOrder.add(key);
      return _cache[key];
    }
    return null;
  }

  void put(String key, MemoryImage newImage) {
    final valueSize = newImage.bytes.lengthInBytes;

    // If the key already exists, update the value
    if (_cache.containsKey(key)) {
      final oldImage = _cache[key]!;
      _currentSize -= oldImage.bytes.lengthInBytes; // Subtract old size
      _cache[key] = newImage;
      _currentSize += valueSize; // Add new size
      _usageOrder.remove(key); // Update usage order
      _usageOrder.add(key);
      return;
    }

    // Evict least recently used items if necessary
    while (_cache.length > 1 &&
        _usageOrder.length > 1 &&
        (_currentSize + valueSize > maxCacheSize)) {
      final oldestKey = _usageOrder.removeAt(0); // Remove least recently used
      _currentSize -= _cache[oldestKey]!.bytes.lengthInBytes;
      _cache.remove(oldestKey);
    }

    // Add the new item
    _cache[key] = newImage;
    _usageOrder.add(key);
    _currentSize += valueSize;
  }

  void clear() {
    _cache.clear();
    _usageOrder.clear();
    _currentSize = 0;
  }

  int get currentSize => _currentSize;

  int get itemCount => _cache.length;
}
