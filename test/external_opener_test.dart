// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:external_opener/external_opener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('external_opener');
  late List<MethodCall> calls;

  void answerWith(Object? result) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return result;
    });
  }

  setUp(() {
    calls = [];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('hands the path and mime type to the Android side', () async {
    answerWith(true);

    final opened = await ExternalOpener.open('/files/Audio/a.m4a', 'audio/mp4');

    expect(opened, isTrue);
    expect(calls.single.method, 'open');
    expect(calls.single.arguments,
        {'path': '/files/Audio/a.m4a', 'mimeType': 'audio/mp4'});
  });

  test('reports false when no app can open the file', () async {
    answerWith(false);

    expect(
        await ExternalOpener.open('/files/Video/v.mp4', 'video/mp4'), isFalse);
  });

  test('reports false when the Android side answers nothing', () async {
    answerWith(null);

    expect(
        await ExternalOpener.open('/files/Video/v.mp4', 'video/mp4'), isFalse);
  });
}
