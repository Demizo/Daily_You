import 'dart:convert';
import 'dart:math';

import 'package:daily_you/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/flashback.dart';
import 'package:daily_you/time_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DailyFlashbackPicks {
  String date;
  int? goodDayEntryId;
  int? randomDayEntryId;

  _DailyFlashbackPicks(this.date, {this.goodDayEntryId, this.randomDayEntryId});

  factory _DailyFlashbackPicks.fromJson(Map<String, dynamic> json) =>
      _DailyFlashbackPicks(
        json['date'] as String,
        goodDayEntryId: json['goodDayEntryId'] as int?,
        randomDayEntryId: json['randomDayEntryId'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'goodDayEntryId': goodDayEntryId,
        'randomDayEntryId': randomDayEntryId,
      };
}

class FlashbackManager {
  static const String _dailyPicksPrefsKey = 'flashbackDailyPickCache';

  static _DailyFlashbackPicks _dailyPicks = _DailyFlashbackPicks('');
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_dailyPicksPrefsKey);
    if (raw == null) return;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        _dailyPicks = _DailyFlashbackPicks.fromJson(decoded);
      }
    } catch (_) {
      // Fall back to empty
    }
  }

  static void _persistDailyPicks() {
    final encoded = json.encode(_dailyPicks.toJson());
    final prefs = _prefs;
    if (prefs != null) {
      prefs.setString(_dailyPicksPrefsKey, encoded);
    } else {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_dailyPicksPrefsKey, encoded));
    }
  }

  static Entry? _resolveDailyPick({
    required int? cachedId,
    required void Function(int? entryId) setCachedId,
    required List<Entry> pool,
    required Set<Entry> usedEntries,
    required int? seed,
  }) {
    if (cachedId != null) {
      for (final entry in pool) {
        if (entry.id == cachedId && !usedEntries.contains(entry)) {
          return entry;
        }
      }
    }

    if (pool.isEmpty) return null;
    final random = Random(seed);
    for (int attempt = 0; attempt < pool.length; attempt++) {
      final candidate = pool[random.nextInt(pool.length)];
      if (!usedEntries.contains(candidate)) {
        setCachedId(candidate.id);
        _persistDailyPicks();
        return candidate;
      }
    }
    return null;
  }

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
    final isJalali = TimeManager.isJalaliCalendar(context);
    final now = DateTime.now();

    // Time based memories
    for (var entry in filteredEntries.reversed.toList()) {
      if (usedEntries.contains(entry)) continue;
      if (configProvider.get(ConfigKey.showflashbackYearsAgo) &&
          TimeManager.isSameCalendarDayOfYear(
              entry.timeCreate, now, isJalali) &&
          TimeManager.calendarYearOf(entry.timeCreate, isJalali) !=
              TimeManager.calendarYearOf(now, isJalali)) {
        var yearsAgo = TimeManager.calendarYearOf(now, isJalali) -
            TimeManager.calendarYearOf(entry.timeCreate, isJalali);
        onThisDayEntries.add(entry);
        onThisDayLabels
            .add(AppLocalizations.of(context)!.flashbackYear(yearsAgo));
        usedEntries.add(entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback6MonthsAgo) &&
          TimeManager.datesExactCalendarMonthDiff(
                  entry.timeCreate, now, isJalali) ==
              6) {
        final label = AppLocalizations.of(context)!.flashbackMonth(6);
        singleFlashbacks.putIfAbsent(label, () => []).add(entry);
        usedEntries.add(entry);
        continue;
      }
      if (configProvider.get(ConfigKey.showflashback1MonthAgo) &&
          TimeManager.datesExactCalendarMonthDiff(
                  entry.timeCreate, now, isJalali) ==
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
      int? seed = int.tryParse("${now.year}${now.month}${now.day}");
      final todayKey = "${now.year}-${now.month}-${now.day}";
      if (_dailyPicks.date != todayKey) {
        _dailyPicks = _DailyFlashbackPicks(todayKey);
      }

      // A happy memory
      if (configProvider.get(ConfigKey.showflashbackGoodDay)) {
        final goodDayEntry = _resolveDailyPick(
          cachedId: _dailyPicks.goodDayEntryId,
          setCachedId: (id) => _dailyPicks.goodDayEntryId = id,
          pool: happyEntries,
          usedEntries: usedEntries,
          seed: seed,
        );
        if (goodDayEntry != null) {
          final label = AppLocalizations.of(context)!.flashbackGoodDay;
          singleFlashbacks.putIfAbsent(label, () => []).add(goodDayEntry);
          usedEntries.add(goodDayEntry);
        }
      }

      // A random memory
      if (configProvider.get(ConfigKey.showflashbackRandomDay)) {
        final randomDayEntry = _resolveDailyPick(
          cachedId: _dailyPicks.randomDayEntryId,
          setCachedId: (id) => _dailyPicks.randomDayEntryId = id,
          pool: filteredEntries,
          usedEntries: usedEntries,
          seed: seed,
        );
        if (randomDayEntry != null) {
          final label = AppLocalizations.of(context)!.flashbackRandomDay;
          singleFlashbacks.putIfAbsent(label, () => []).add(randomDayEntry);
          usedEntries.add(randomDayEntry);
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
                .map((e) => TimeManager.localizedTimeFormat(locale)
                    .format(e.timeCreate))
                .toList(),
      ));
    });
    return flashbacksList;
  }
}
