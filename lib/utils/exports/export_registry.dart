// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/file_store.dart';
import 'package:daily_you/utils/exports/export_csv.dart';
import 'package:daily_you/utils/exports/export_format.dart';
import 'package:daily_you/utils/exports/export_json.dart';
import 'package:daily_you/utils/exports/export_markdown.dart';
import 'package:daily_you/utils/exports/export_snapshot.dart';

export 'package:daily_you/utils/exports/export_format.dart';

typedef ExportWriter = Future<Map<String, String>> Function(
    ExportSnapshot snapshot, FileStore store);

class ExportFormatOption {
  const ExportFormatOption(
    this.format,
    this.name,
    this.write, {
    this.documentName,
    this.documentMimeType,
  });

  final ExportFormat format;
  final String Function(AppLocalizations localizations) name;
  final ExportWriter write;
  final String? documentName;
  final String? documentMimeType;
}

class ExportRegistry {
  const ExportRegistry(this.options);

  static final ExportRegistry instance = ExportRegistry([
    ExportFormatOption(
      ExportFormat.markdown,
      (localizations) => localizations.formatMarkdown,
      writeMarkdown,
    ),
    ExportFormatOption(
      ExportFormat.csv,
      (localizations) => localizations.formatCsv,
      writeCsv,
      documentName: csvDocumentName,
      documentMimeType: 'text/csv',
    ),
    ExportFormatOption(
      ExportFormat.json,
      (localizations) => localizations.formatJson,
      writeJson,
      documentName: jsonDocumentName,
      documentMimeType: 'application/json',
    ),
  ]);

  final List<ExportFormatOption> options;

  ExportFormatOption optionFor(ExportFormat format) =>
      options.firstWhere((option) => option.format == format);
}
