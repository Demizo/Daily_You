// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const pinnedTimeZone = 'TST-7';

typedef _SetEnvironment = int Function(Pointer<Uint8>, Pointer<Uint8>, int);
typedef _SetEnvironmentNative = Int32 Function(
    Pointer<Uint8>, Pointer<Uint8>, Int32);

void usePinnedTimeZone() {
  final library = DynamicLibrary.process();
  final allocate = library.lookupFunction<Pointer<Uint8> Function(IntPtr),
      Pointer<Uint8> Function(int)>('malloc');
  final release = library.lookupFunction<Void Function(Pointer<Uint8>),
      void Function(Pointer<Uint8>)>('free');
  final setEnvironment =
      library.lookupFunction<_SetEnvironmentNative, _SetEnvironment>('setenv');
  final applyTimeZone =
      library.lookupFunction<Void Function(), void Function()>('tzset');

  void setTimeZone(String value) {
    final name = _cString('TZ', allocate);
    final text = _cString(value, allocate);
    setEnvironment(name, text, 1);
    release(name);
    release(text);
    applyTimeZone();
  }

  final originalTimeZone = Platform.environment['TZ'];

  setUpAll(() => setTimeZone(pinnedTimeZone));
  tearDownAll(() => setTimeZone(originalTimeZone ?? ''));
}

Pointer<Uint8> _cString(String value, Pointer<Uint8> Function(int) allocate) {
  final bytes = value.codeUnits;
  final pointer = allocate(bytes.length + 1);
  pointer.asTypedList(bytes.length + 1)
    ..setAll(0, bytes)
    ..[bytes.length] = 0;
  return pointer;
}
