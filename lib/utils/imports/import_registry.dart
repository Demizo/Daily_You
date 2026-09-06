import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/imports/import_daybook.dart' as daybook;
import 'package:daily_you/utils/imports/import_daylio.dart' as daylio;
import 'package:daily_you/utils/imports/import_diarium.dart' as diarium;
import 'package:daily_you/utils/imports/import_diaro.dart' as diaro;
import 'package:daily_you/utils/imports/import_format.dart';
import 'package:daily_you/utils/imports/import_json.dart' as json;
import 'package:daily_you/utils/imports/import_mybrain.dart' as mybrain;
import 'package:daily_you/utils/imports/import_oneshot.dart' as oneshot;
import 'package:daily_you/utils/imports/import_pixels.dart' as pixels;
import 'package:flutter/widgets.dart';

export 'package:daily_you/utils/imports/import_format.dart';

typedef ImportRunner = Future<bool> Function(
    BuildContext context, Function(String) updateStatus);

class ImportFormatOption {
  const ImportFormatOption(this.format, this.name, this.run);

  final ImportFormat format;
  final String Function(AppLocalizations localizations) name;
  final ImportRunner run;
}

class ImportRegistry {
  const ImportRegistry(this.options);

  static final ImportRegistry instance = ImportRegistry([
    ImportFormatOption(
      ImportFormat.dailyYouJson,
      (localizations) => localizations.formatDailyYouJson,
      (context, updateStatus) => json.importFromJson(updateStatus),
    ),
    ImportFormatOption(
      ImportFormat.daybook,
      (localizations) => localizations.formatDaybook,
      daybook.importFromDaybook,
    ),
    ImportFormatOption(
      ImportFormat.daylio,
      (localizations) => localizations.formatDaylio,
      daylio.importFromDaylio,
    ),
    ImportFormatOption(
      ImportFormat.diarium,
      (localizations) => localizations.formatDiarium,
      diarium.importFromDiarium,
    ),
    ImportFormatOption(
      ImportFormat.diaro,
      (localizations) => localizations.formatDiaro,
      diaro.importFromDiaro,
    ),
    ImportFormatOption(
      ImportFormat.myBrain,
      (localizations) => localizations.formatMyBrain,
      (context, updateStatus) => mybrain.importFromMyBrain(updateStatus),
    ),
    ImportFormatOption(
      ImportFormat.oneShot,
      (localizations) => localizations.formatOneShot,
      (context, updateStatus) => oneshot.importFromOneShot(updateStatus),
    ),
    ImportFormatOption(
      ImportFormat.pixels,
      (localizations) => localizations.formatPixels,
      (context, updateStatus) => pixels.importFromPixels(updateStatus),
    ),
  ]);

  final List<ImportFormatOption> options;

  ImportFormatOption optionFor(ImportFormat format) =>
      options.firstWhere((option) => option.format == format);
}
