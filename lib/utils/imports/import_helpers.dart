import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_images_provider.dart';

Future<void> finishImport(Function(String) updateStatus,
    {bool syncImages = false}) async {
  await EntriesProvider.instance.load();
  await EntryImagesProvider.instance.load();
  if (syncImages && ImageStorage.instance.usingExternalLocation()) {
    await ImageStorage.instance.syncImageFolder(true, updateStatus: updateStatus);
  }
}

DateTime diariumIdToDateTime(int ticks) {
  const int ticksAtUnixEpoch = 621355968000000000;
  final usSinceEpoch = ((ticks - ticksAtUnixEpoch) / 10).round();
  return DateTime.fromMicrosecondsSinceEpoch(usSinceEpoch, isUtc: false);
}

DateTime convertWithOffset(int millisUtc, String tzOffset) {
  final utc = DateTime.fromMillisecondsSinceEpoch(millisUtc, isUtc: true);
  final sign = tzOffset.startsWith('-') ? -1 : 1;
  final parts = tzOffset.substring(1).split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  final offsetDuration = Duration(
    hours: hours * sign,
    minutes: minutes * sign,
  );
  return utc.add(offsetDuration);
}

DateTime parseDaybookLocal(String s) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})-(\d{2}):(\d{2})$',
  ).firstMatch(s);

  if (match == null) {
    throw FormatException("Invalid Daybook date: $s");
  }

  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
  );
}
