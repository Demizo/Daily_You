import 'dart:math';

import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/time_manager.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FlashbackManager {
  static List<Flashback> getFlashbacks(
      BuildContext context, List<Entry> entries) {
    final configProvider = Provider.of<ConfigProvider>(context);

    List<Entry> filteredEntries = entries;

    if (configProvider.get(ConfigKey.excludeBadDaysFromFlashbacks)) {
      // Filter out unhappy entries
      filteredEntries =
          filteredEntries.where((entry) => (entry.mood ?? 0) >= 0).toList();
    }

    List<Flashback> flashbacksList = List.empty(growable: true);
    Map<String, List<Entry>> singleFlashbacks = {};
    List<Entry> onThisDayEntries = [];
    List<String> onThisDayLabels = [];

    List<Entry> happyEntries = List.empty(growable: true);
    Set<Entry> usedEntries = {};

    if (filteredEntries.isEmpty) return flashbacksList;

    final locale = TimeManager.currentLocale(context);

    // Time based memories
    for (var entry in filteredEntries.reversed.toList()) {
      if (usedEntries.contains(entry)) continue;
      if (configProvider.get(ConfigKey.showflashbackYearsAgo) &&
          entry.timeCreate.day == DateTime.now().day &&
          entry.timeCreate.month == DateTime.now().month &&
          entry.timeCreate.year != DateTime.now().year) {
        var yearsAgo = DateTime.now().year - entry.timeCreate.year;
        onThisDayEntries.add(entry);
        onThisDayLabels
            .add(AppLocalizations.of(context)!.flashbackYear(yearsAgo));
        usedEntries.add(entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback6MonthsAgo) &&
          TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
              6) {
        final label = AppLocalizations.of(context)!.flashbackMonth(6);
        singleFlashbacks.putIfAbsent(label, () => []).add(entry);
        usedEntries.add(entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback1MonthAgo) &&
          TimeManager.datesExactMonthDiff(entry.timeCreate, DateTime.now()) ==
              1) {
        final label = AppLocalizations.of(context)!.flashbackMonth(1);
        singleFlashbacks.putIfAbsent(label, () => []).add(entry);
        usedEntries.add(entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback1WeekAgo) &&
          TimeManager.isSameDay(entry.timeCreate,
              DateTime.now().subtract(const Duration(days: 7)))) {
        final label = AppLocalizations.of(context)!.flashbackWeek(1);
        singleFlashbacks.putIfAbsent(label, () => []).add(entry);
        usedEntries.add(entry);
        continue;
      }
      if (entry.mood == 1 || entry.mood == 2) {
        happyEntries.add(entry);
        continue;
      }
    }

    if (onThisDayEntries.isNotEmpty) {
      final onThisDayTitle = AppLocalizations.of(context)!.flashbackOnThisDay;
      flashbacksList.add(Flashback(
        title: onThisDayTitle,
        entries: onThisDayEntries.reversed.toList(), // Most recent first
        entryLabels: onThisDayLabels.reversed.toList(), // Most recent first
        isOnThisDay: true,
      ));
    }

    // Random Memories
    if (filteredEntries.length > 7) {
      int? seed = int.tryParse(
          "${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}");

      // A happy memory
      if (configProvider.get(ConfigKey.showflashbackGoodDay)) {
        Random random = Random(seed);
        int index = 0;
        while (index < happyEntries.length) {
          Entry randomEntry = happyEntries[random.nextInt(happyEntries.length)];
          if (usedEntries.contains(randomEntry)) {
            index++;
            continue;
          }
          final label = AppLocalizations.of(context)!.flashbackGoodDay;
          singleFlashbacks.putIfAbsent(label, () => []).add(randomEntry);
          usedEntries.add(randomEntry);
          break;
        }
      }

      // A random memory
      if (configProvider.get(ConfigKey.showflashbackRandomDay)) {
        Random random = Random(seed);
        int index = 0;
        while (index < filteredEntries.length) {
          Entry randomEntry =
              filteredEntries[random.nextInt(filteredEntries.length)];
          if (usedEntries.contains(randomEntry)) {
            index++;
            continue;
          }
          final label = AppLocalizations.of(context)!.flashbackRandomDay;
          singleFlashbacks.putIfAbsent(label, () => []).add(randomEntry);
          usedEntries.add(randomEntry);
          break;
        }
      }
    }

    singleFlashbacks.forEach((label, entries) {
      flashbacksList.add(Flashback(
        title: label,
        entries: entries,
        entryLabels: entries.length == 1
            ? [label]
            : entries
                .map((e) => DateFormat.jm(locale).format(e.timeCreate))
                .toList(),
      ));
    });
    return flashbacksList;
  }
}
