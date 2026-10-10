// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SharePayload {
  final String? text;
  final List<String> imagePaths;

  const SharePayload({this.text, this.imagePaths = const []});

  void deleteImages() {
    for (final path in imagePaths) {
      try {
        File(path).deleteSync();
      } on FileSystemException {
        continue;
      }
    }
    for (final directory in {
      for (final path in imagePaths) File(path).parent
    }) {
      try {
        directory.deleteSync();
      } on FileSystemException {
        continue;
      }
    }
  }

  @visibleForTesting
  static SharePayload? fromMap(Map<Object?, Object?>? map) {
    if (map == null) return null;
    final text = map['text'] as String?;
    final imagePaths = [
      for (final path in (map['imagePaths'] as List<Object?>? ?? const []))
        path as String,
    ];
    if (text == null && imagePaths.isEmpty) return null;
    return SharePayload(text: text, imagePaths: imagePaths);
  }
}

class ShareReceiver {
  static final ShareReceiver instance = ShareReceiver._internal();
  ShareReceiver._internal();

  static const _channel = MethodChannel('share_receiver');

  late final _controller =
      StreamController<SharePayload>.broadcast(onListen: _start);

  /// Emits the share that launched the app, if any, then every later share.
  Stream<SharePayload> get shares => _controller.stream;

  void _start() {
    _channel.setMethodCallHandler((call) async {
      // Without a listener the share stays pending until the next listen.
      if (call.method == 'shareReceived' && _controller.hasListener) {
        await _consume();
      }
    });
    _consume();
  }

  Future<void> _consume() async {
    final payload = SharePayload.fromMap(
        await _channel.invokeMapMethod<Object?, Object?>('consumeShare'));
    if (payload != null) _controller.add(payload);
  }
}
