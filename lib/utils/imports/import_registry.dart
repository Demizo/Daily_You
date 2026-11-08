// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_daybook.dart' as daybook;
import 'package:daily_you/utils/imports/import_daylio.dart' as daylio;
import 'package:daily_you/utils/imports/import_diarium.dart' as diarium;
import 'package:daily_you/utils/imports/import_diaro.dart' as diaro;
import 'package:daily_you/utils/imports/import_format.dart';
import 'package:daily_you/utils/imports/import_json.dart' as json;
import 'package:daily_you/utils/imports/import_mybrain.dart' as mybrain;
import 'package:daily_you/utils/imports/import_oneshot.dart' as oneshot;
import 'package:daily_you/utils/imports/import_pixels.dart' as pixels;
import 'package:daily_you/utils/imports/import_runner.dart';
import 'package:daily_you/utils/imports/import_source.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:flutter/widgets.dart';

export 'package:daily_you/utils/imports/import_format.dart';

const _jsonExtensions = ['json'];
const _jsonMimeTypes = ['application/json'];
const _jsonAndZipExtensions = ['json', 'zip'];
const _jsonAndZipMimeTypes = ['application/json', 'application/zip'];

class ImportFormatOption {
  const ImportFormatOption(
    this.format,
    this.name,
    this.parse, {
    this.kind = ImportSourceKind.file,
    this.pickerExtensions,
    this.pickerMimeTypes,
  });

  final ImportFormat format;
  final String Function(AppLocalizations localizations) name;
  final ImportParser parse;
  final ImportSourceKind kind;
  final List<String>? pickerExtensions;
  final List<String>? pickerMimeTypes;

  Future<OperationOutcome> run(
    BuildContext context,
    void Function(String) updateStatus, {
    ImportFilePicker pickFile = StoragePicker.pickFile,
  }) =>
      runImport(context, updateStatus,
          kind: kind,
          parse: parse,
          pickerExtensions: pickerExtensions,
          pickerMimeTypes: pickerMimeTypes,
          pickFile: pickFile);
}

class ImportRegistry {
  const ImportRegistry(this.options);

  static final ImportRegistry instance = ImportRegistry([
    ImportFormatOption(
      ImportFormat.dailyYouJson,
      (localizations) => localizations.formatDailyYouJson,
      (source, _) => json.parseJson(source),
      pickerExtensions: _jsonAndZipExtensions,
      pickerMimeTypes: _jsonAndZipMimeTypes,
    ),
    ImportFormatOption(
      ImportFormat.daybook,
      (localizations) => localizations.formatDaybook,
      (source, _) => daybook.parseDaybook(source),
      kind: ImportSourceKind.archive,
    ),
    ImportFormatOption(
      ImportFormat.daylio,
      (localizations) => localizations.formatDaylio,
      (source, _) => daylio.parseDaylio(source),
      kind: ImportSourceKind.archive,
    ),
    ImportFormatOption(
      ImportFormat.diarium,
      (localizations) => localizations.formatDiarium,
      (source, localizations) => diarium.parseDiarium(source,
          peopleCategoryName: localizations.tagCategoryPeopleName),
    ),
    ImportFormatOption(
      ImportFormat.diaro,
      (localizations) => localizations.formatDiaro,
      (source, _) => diaro.parseDiaro(source),
      kind: ImportSourceKind.archive,
    ),
    ImportFormatOption(
      ImportFormat.myBrain,
      (localizations) => localizations.formatMyBrain,
      (source, _) => mybrain.parseMyBrain(source),
      pickerExtensions: _jsonExtensions,
      pickerMimeTypes: _jsonMimeTypes,
    ),
    ImportFormatOption(
      ImportFormat.oneShot,
      (localizations) => localizations.formatOneShot,
      (source, _) => oneshot.parseOneShot(source),
      pickerExtensions: _jsonExtensions,
      pickerMimeTypes: _jsonMimeTypes,
    ),
    ImportFormatOption(
      ImportFormat.pixels,
      (localizations) => localizations.formatPixels,
      (source, _) => pixels.parsePixels(source),
      pickerExtensions: _jsonExtensions,
      pickerMimeTypes: _jsonMimeTypes,
    ),
  ]);

  final List<ImportFormatOption> options;

  ImportFormatOption optionFor(ImportFormat format) =>
      options.firstWhere((option) => option.format == format);
}
