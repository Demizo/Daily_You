// Behavior based on DenserMeerkat/June (GPL-3.0)
import 'dart:convert';

import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/imports/import_helpers.dart';
import 'package:daily_you/utils/markdown_io_helper.dart';
import 'package:daily_you/utils/operation_outcome.dart';

Future<OperationOutcome> importFromMarkdown(
    Function(String) updateStatus) async {
  updateStatus("0%");
  var outcome = const OperationOutcome.succeeded();

  try {
    final selectedFile = await StoragePicker.pickFile(
      allowedExtensions: ['md', 'markdown', 'txt'],
      mimeTypes: ['text/markdown', 'text/plain'],
    );
    if (selectedFile == null) return const OperationOutcome.cancelled();

    final bytes = await selectedFile.readBytes();
    if (bytes == null) return const OperationOutcome.failed();

    final content = utf8.decode(bytes);
    final entry = MarkdownIoHelper.parseMarkdownEntry(content);

    await addImportedEntries([ImportedEntry(entry)], updateStatus);
  } catch (error) {
    outcome = OperationOutcome.failed(error);
  }

  return finishImport(updateStatus, outcome);
}
