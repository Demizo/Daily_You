import 'package:daily_you/utils/imports/import_daybook.dart' as daybook;
import 'package:daily_you/utils/imports/import_daylio.dart' as daylio;
import 'package:daily_you/utils/imports/import_diarium.dart' as diarium;
import 'package:daily_you/utils/imports/import_diaro.dart' as diaro;
import 'package:daily_you/utils/imports/import_json.dart' as importjson;
import 'package:daily_you/utils/imports/import_mybrain.dart' as mybrain;
import 'package:daily_you/utils/imports/import_oneshot.dart' as oneshot;
import 'package:daily_you/utils/imports/import_pixels.dart' as pixels;
import 'package:flutter/material.dart';

export 'package:daily_you/utils/imports/import_format.dart';

class ImportUtils {
  static Future<bool> importFromJson(Function(String) updateStatus) =>
      importjson.importFromJson(updateStatus);

  static Future<bool> importFromOneShot(Function(String) updateStatus) =>
      oneshot.importFromOneShot(updateStatus);

  static Future<bool> importFromPixels(Function(String) updateStatus) =>
      pixels.importFromPixels(updateStatus);

  static Future<bool> importFromMyBrain(Function(String) updateStatus) =>
      mybrain.importFromMyBrain(updateStatus);

  static Future<bool> importFromDiarium(
          BuildContext context, Function(String) updateStatus) =>
      diarium.importFromDiarium(context, updateStatus);

  static Future<bool> importFromDaylio(
          BuildContext context, Function(String) updateStatus) =>
      daylio.importFromDaylio(context, updateStatus);

  static Future<bool> importFromDiaro(
          BuildContext context, Function(String) updateStatus) =>
      diaro.importFromDiaro(context, updateStatus);

  static Future<bool> importFromDaybook(
          BuildContext context, Function(String) updateStatus) =>
      daybook.importFromDaybook(context, updateStatus);
}
