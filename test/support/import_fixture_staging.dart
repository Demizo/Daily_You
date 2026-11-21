// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:convert';
import 'dart:io';

import 'package:daily_you/utils/imports/import_archive.dart';
import 'package:daily_you/utils/imports/import_registry.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show basename, join, relative;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'import_fixtures.dart';
import 'import_run_harness.dart';

Future<Directory> _stagingDirectory(String name) async {
  final directory = await Directory.systemTemp.createTemp(name);
  addTearDown(() => directory.delete(recursive: true));
  return directory;
}

Future<ImportSource> stageDaylioFixture() async {
  final input = fixtureInputDirectory(ImportFormat.daylio);
  final staged = await _stagingDirectory('daylio_fixture');

  for (final file in input.listSync(recursive: true).whereType<File>()) {
    final relativePath = relative(file.path, from: input.path);
    if (relativePath == 'backup.json') continue;
    final target = File(join(staged.path, relativePath));
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }

  final backup = await File(join(input.path, 'backup.json')).readAsBytes();
  final encoded = base64.encode(backup);
  final wrapped = [
    for (var start = 0; start < encoded.length; start += 76)
      encoded.substring(start, (start + 76).clamp(0, encoded.length)),
  ].join('\r\n');
  await File(join(staged.path, 'backup.daylio')).writeAsString(wrapped);

  return ImportSource(staged.path, 'fixture.zip');
}

Future<ImportSource> stageDiariumFixture() async {
  final input = fixtureInputDirectory(ImportFormat.diarium);
  final staged = await _stagingDirectory('diarium_fixture');
  const databaseName = 'Diarium.db';

  databaseFactory = databaseFactoryFfi;
  final database =
      await databaseFactory.openDatabase(join(staged.path, databaseName));
  final script = await File(join(input.path, 'diarium.sql')).readAsString();
  for (final statement in script.split(';\n')) {
    if (statement.trim().isNotEmpty) await database.execute(statement);
  }
  await database.close();

  return ImportSource(staged.path, databaseName);
}

Future<ImportSource> stageDayOneFixture() async {
  final archive = File(
      await zipDirectoryContents(fixtureInputDirectory(ImportFormat.dayOne)));
  return ImportSource(archive.parent.path, basename(archive.path));
}

Directory extractedDayOneFixture(ImportSource source) =>
    Directory(join(source.directoryPath, extractedArchiveFolderName));
