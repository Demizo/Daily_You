import 'dart:io';

import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/database/image_storage.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/image.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/entry_images_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/generated/tag_icon_registry.dart';

class ScreenshotSeedEntry {
  const ScreenshotSeedEntry({
    required this.daysAgo,
    required this.mood,
    this.imageCount = 0,
  });

  final int daysAgo;
  final int mood;
  final int imageCount;
}

const recentHighlights = <ScreenshotSeedEntry>[
  ScreenshotSeedEntry(daysAgo: 1, mood: 2, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 2, mood: 1, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 3, mood: 1, imageCount: 2),
  ScreenshotSeedEntry(daysAgo: 4, mood: -1, imageCount: 3),
  ScreenshotSeedEntry(daysAgo: 5, mood: 2, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 6, mood: 1, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 7, mood: 2, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 8, mood: 0, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 9, mood: 0, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 10, mood: 1, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 11, mood: 2, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 12, mood: -1, imageCount: 1),
  ScreenshotSeedEntry(daysAgo: 13, mood: 1, imageCount: 1),
];

const _pictureWindowEndDaysAgo = 60;
const _moodWaveStartDaysAgo = 14;
const _moodWaveEndDaysAgo = 199;
const _longTailStep = 2;

const moodWaveTable = <int>[
  0, 1, 1, 2, 1, 1, -1, 0, 0, 0, 2, 1, 0, 0, 1, 1, 1, 1, 0, 0, //
  0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, -2, 1, 0, //
  1, 1, 1, 0, 0, 2, 1, 1, 0, -1, 0, 0, 0, 1, 1, 0, 0, 2, -1, 0, //
  0, 0, 0, 1, -1, 0, 1, 1, 2, 0, 2, 0, 0, 1, 0, 0, 1, 0, -1, 0, //
  0, -2, 1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 2, 1, 1, 0, -1, 0, //
  0, 0, 0, 0, 0, 0, -1, 2, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, -2, 0, //
  0, -2, 1, -1, 0, 0, -1, 0, 0, 2, 0, 0, 0, 1, 0, -1, -1, 0, 0, 0, //
  0, -2, 0, 1, 0, 0, 2, -1, -1, -1, 1, 1, 0, 0, -1, 0, 0, 0, 0, -1, //
  -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 1, -1, -1, -2, -1, -1, 0, 0, 0, 0, //
  0, 0, 0, -1, -1, -1,
];

List<ScreenshotSeedEntry> moodWaveEntries() {
  final entries = <ScreenshotSeedEntry>[];
  var daysAgo = _moodWaveStartDaysAgo;
  while (daysAgo <= _moodWaveEndDaysAgo) {
    final hasPicture = daysAgo <= _pictureWindowEndDaysAgo;
    entries.add(ScreenshotSeedEntry(
      daysAgo: daysAgo,
      mood: moodWaveTable[daysAgo - _moodWaveStartDaysAgo],
      imageCount: hasPicture ? 1 : 0,
    ));
    daysAgo += hasPicture ? 1 : _longTailStep;
  }
  return entries;
}

int _oneMonthAgoOffset(DateTime now) =>
    now.difference(DateTime(now.year, now.month - 1, now.day)).inDays;
int _sixMonthsAgoOffset(DateTime now) =>
    now.difference(DateTime(now.year, now.month - 6, now.day)).inDays;
int _oneYearAgoOffset(DateTime now) =>
    now.difference(DateTime(now.year - 1, now.month, now.day)).inDays;

// Which photo each flashback anchor uses. Edit to swap.
Map<int, String> explicitFlashbackImages(DateTime now) => {
      7: 'flashback_1_week.jpg',
      _oneMonthAgoOffset(now): 'flashback_1_month.jpg',
      _sixMonthsAgoOffset(now): 'flashback_6_months.jpg',
      _oneYearAgoOffset(now): 'flashback_1_year.jpg',
    };

class _RecentTagSeed {
  const _RecentTagSeed(this.iconKey, {this.trackerValue});

  final String iconKey;
  final String? trackerValue;
}

const _recentTags = <int, List<_RecentTagSeed>>{
  1: [_RecentTagSeed(TagIconKey.favorite)],
  2: [_RecentTagSeed(TagIconKey.fitnessCenter)],
  3: [_RecentTagSeed(TagIconKey.batteryChargingFull, trackerValue: '6')],
  5: [
    _RecentTagSeed(TagIconKey.spa),
    _RecentTagSeed(TagIconKey.groups),
  ],
  6: [_RecentTagSeed(TagIconKey.celebration)],
  8: [
    _RecentTagSeed(TagIconKey.localDining),
    _RecentTagSeed(TagIconKey.batteryChargingFull, trackerValue: '8'),
  ],
  9: [_RecentTagSeed(TagIconKey.volunteerActivism)],
  11: [
    _RecentTagSeed(TagIconKey.favorite),
    _RecentTagSeed(TagIconKey.fitnessCenter),
  ],
  12: [_RecentTagSeed(TagIconKey.nightlight)],
  13: [
    _RecentTagSeed(TagIconKey.cleaningServices),
    _RecentTagSeed(TagIconKey.batteryChargingFull, trackerValue: '4'),
  ],
};

class ScreenshotSeeder {
  ScreenshotSeeder({
    required this.curatedImagesDirectory,
    required this.entryText,
  });

  final Directory curatedImagesDirectory;
  final String entryText;

  List<File>? _curatedImageFiles;

  List<File> _curatedImages() {
    return _curatedImageFiles ??= curatedImagesDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.jpg'))
        .where((file) => !file.uri.pathSegments.last.startsWith('flashback_'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  Future<void> seed(DateTime now) async {
    await TagsProvider.instance.load();
    final tagsByIconKey = {
      for (final tag in TagsProvider.instance.tags) tag.icon: tag,
    };
    final explicitImages = explicitFlashbackImages(now);

    final covered = {
      for (final seed in recentHighlights) seed.daysAgo,
      for (final seed in moodWaveEntries()) seed.daysAgo,
    };

    var imageCursor = 0;
    for (final seed in recentHighlights) {
      imageCursor = await _seedEntry(
          now, seed, imageCursor, tagsByIconKey, explicitImages);
    }
    for (final seed in moodWaveEntries()) {
      imageCursor = await _seedEntry(
          now, seed, imageCursor, tagsByIconKey, explicitImages);
    }
    for (final daysAgo in explicitImages.keys) {
      if (covered.contains(daysAgo)) continue;
      final seed =
          ScreenshotSeedEntry(daysAgo: daysAgo, mood: 1, imageCount: 1);
      imageCursor = await _seedEntry(
          now, seed, imageCursor, tagsByIconKey, explicitImages);
    }
  }

  Future<int> _seedEntry(
      DateTime now,
      ScreenshotSeedEntry seed,
      int imageCursor,
      Map<String?, Tag> tagsByIconKey,
      Map<int, String> explicitImages) async {
    final timestamp = now.subtract(Duration(days: seed.daysAgo));
    final entry = await EntryStore.instance.add(
      Entry(
        text: entryText,
        mood: seed.mood,
        timeCreate: timestamp,
        timeModified: timestamp,
      ),
      skipUpdate: true,
    );

    final explicitImageName = explicitImages[seed.daysAgo];
    final images = _curatedImages();
    for (var rank = 0; rank < seed.imageCount; rank++) {
      final sourceFile = explicitImageName != null && rank == 0
          ? File('${curatedImagesDirectory.path}/$explicitImageName')
          : images.isEmpty
              ? null
              : images[imageCursor++ % images.length];
      if (sourceFile == null) continue;
      final bytes = await sourceFile.readAsBytes();
      final imageName = await ImageStorage.instance.create(
        sourceFile.uri.pathSegments.last,
        bytes,
        currTime: timestamp,
      );
      if (imageName == null) continue;
      await EntryImagesProvider.instance.add(
        EntryImage(
          entryId: entry.id,
          imgPath: imageName,
          imgRank: rank,
          timeCreate: timestamp,
        ),
        skipUpdate: true,
      );
    }

    for (final tagSeed in _recentTags[seed.daysAgo] ?? const []) {
      final tag = tagsByIconKey[tagSeed.iconKey];
      if (tag == null) continue;
      await TagsProvider.instance.addEntryTag(EntryTag(
        entryId: entry.id!,
        tagId: tag.id!,
        value: tagSeed.trackerValue,
        timeCreate: timestamp,
      ));
    }

    return imageCursor;
  }
}
