// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:async';

import 'package:daily_you/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _SlowClosingDatabase implements Database {
  final Completer<void> closing = Completer();

  @override
  Future<void> close() => closing.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => AppDatabase.instance.database = null);

  test('close completes only once the database has finished closing', () async {
    final database = _SlowClosingDatabase();
    AppDatabase.instance.database = database;

    var closed = false;
    final closing = AppDatabase.instance.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);

    database.closing.complete();
    await closing;
    expect(closed, isTrue);
  });
}
