// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/attachment.dart';

enum TagFilterMode { all, any }

enum TextTermJoin { all, any }

sealed class DateSelection {
  const DateSelection();
}

final class NoDateSelection extends DateSelection {
  const NoDateSelection();
}

final class LastMonthsSelection extends DateSelection {
  const LastMonthsSelection(this.months, {required this.isJalali});

  final int months;
  final bool isJalali;
}

final class CalendarYearSelection extends DateSelection {
  const CalendarYearSelection(this.year, {required this.isJalali});

  final int year;
  final bool isJalali;
}

final class CustomRangeSelection extends DateSelection {
  const CustomRangeSelection(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class GalleryFilter {
  const GalleryFilter({
    this.moods = const {},
    this.noMood = false,
    this.tagIds = const {},
    this.tagMode = TagFilterMode.any,
    this.noTags = false,
    this.date = const NoDateSelection(),
    this.attachmentTypes = const {},
    this.noAttachments = false,
    this.noText = false,
    this.textTerms = const [],
    this.textJoin = TextTermJoin.all,
    this.textMatchCase = false,
    this.searchText = '',
  });

  final Set<int> moods;
  final bool noMood;
  final Set<int> tagIds;
  final TagFilterMode tagMode;
  final bool noTags;
  final DateSelection date;
  final Set<AttachmentType> attachmentTypes;
  final bool noAttachments;
  final bool noText;
  final List<String> textTerms;
  final TextTermJoin textJoin;
  final bool textMatchCase;
  final String searchText;

  bool get hasMood => moods.isNotEmpty || noMood;
  bool get hasTags => tagIds.isNotEmpty || noTags;
  bool get hasDate => date is! NoDateSelection;
  bool get hasAttachments => attachmentTypes.isNotEmpty || noAttachments;
  bool get hasText => textTerms.isNotEmpty || noText;
  bool get hasSearchText => searchText.isNotEmpty;

  bool get isActive =>
      hasMood ||
      hasTags ||
      hasDate ||
      hasAttachments ||
      hasText ||
      hasSearchText;

  GalleryFilter copyWith({
    Set<int>? moods,
    bool? noMood,
    Set<int>? tagIds,
    TagFilterMode? tagMode,
    bool? noTags,
    DateSelection? date,
    Set<AttachmentType>? attachmentTypes,
    bool? noAttachments,
    bool? noText,
    List<String>? textTerms,
    TextTermJoin? textJoin,
    bool? textMatchCase,
    String? searchText,
  }) =>
      GalleryFilter(
        moods: moods ?? this.moods,
        noMood: noMood ?? this.noMood,
        tagIds: tagIds ?? this.tagIds,
        tagMode: tagMode ?? this.tagMode,
        noTags: noTags ?? this.noTags,
        date: date ?? this.date,
        attachmentTypes: attachmentTypes ?? this.attachmentTypes,
        noAttachments: noAttachments ?? this.noAttachments,
        noText: noText ?? this.noText,
        textTerms: textTerms ?? this.textTerms,
        textJoin: textJoin ?? this.textJoin,
        textMatchCase: textMatchCase ?? this.textMatchCase,
        searchText: searchText ?? this.searchText,
      );

  GalleryFilter withoutMood() => copyWith(moods: const {}, noMood: false);

  GalleryFilter withoutTags() => copyWith(
        tagIds: const {},
        tagMode: TagFilterMode.any,
        noTags: false,
      );

  GalleryFilter withoutDate() => copyWith(date: const NoDateSelection());

  GalleryFilter withoutAttachments() =>
      copyWith(attachmentTypes: const {}, noAttachments: false);

  GalleryFilter withoutText() => copyWith(
        noText: false,
        textTerms: const [],
        textJoin: TextTermJoin.all,
        textMatchCase: false,
      );

  GalleryFilter withoutSearchText() => copyWith(searchText: '');
}
