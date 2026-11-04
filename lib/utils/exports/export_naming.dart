// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/utils/exports/export_snapshot.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class NamedExportAttachment {
  const NamedExportAttachment(this.attachment, this.fileName, this.path);

  final ExportAttachment attachment;
  final String fileName;
  final String path;
}

class NamedExportEntry {
  const NamedExportEntry(this.exported, this.fileStem, this.attachments);

  final ExportEntry exported;
  final String fileStem;
  final List<NamedExportAttachment> attachments;
}

List<NamedExportEntry> nameExportEntries(ExportSnapshot snapshot) {
  final dayFormat = DateFormat('yyyy-MM-dd', snapshot.locale);
  final countByDay = <String, int>{};

  return [
    for (final exported in snapshot.entries)
      _nameEntry(exported, dayFormat, countByDay)
  ];
}

Map<String, String> attachmentSourcesOf(Iterable<NamedExportEntry> entries,
        {String folder = ''}) =>
    {
      for (final named in entries)
        for (final attachment in named.attachments)
          posix.join(folder, attachment.path): attachment.attachment.sourcePath
    };

NamedExportEntry _nameEntry(
    ExportEntry exported, DateFormat dayFormat, Map<String, int> countByDay) {
  final day = dayFormat.format(exported.entry.timeCreate);
  final dayNumber = countByDay[day] = (countByDay[day] ?? 0) + 1;
  final fileStem = dayNumber > 1 ? '${day}_$dayNumber' : day;

  return NamedExportEntry(exported, fileStem, [
    for (final attachment in exported.attachments)
      _nameAttachment(attachment, fileStem)
  ]);
}

NamedExportAttachment _nameAttachment(
    ExportAttachment attachment, String fileStem) {
  final fileName =
      '${attachment.type.name}_${fileStem}_${attachment.rank}${extension(attachment.sourcePath)}';
  return NamedExportAttachment(
      attachment, fileName, posix.join(attachment.type.folderName, fileName));
}
