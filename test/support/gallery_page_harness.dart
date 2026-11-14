// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/database/entry_store.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/models/mood_scale_preset.dart';
import 'package:daily_you/pages/gallery_page.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/providers/entry_attachments_provider.dart';
import 'package:daily_you/providers/gallery_selection.dart';
import 'package:daily_you/providers/mood_scale_provider.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/gallery_selection_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Entry _galleryEntry(int id) => Entry(
      id: id,
      text: 'log $id',
      timeCreate: DateTime(2026, 1, 31 - id),
      timeModified: DateTime(2026, 1, 31 - id),
    );

Future<void> pumpGalleryPage(WidgetTester tester, {int entryCount = 2}) async {
  MoodScaleProvider.instance.levels = MoodScalePreset.emoji.levels;
  EntryAttachmentsProvider.instance.isLoaded = true;
  EntryStore.instance.entries = [
    for (var id = 1; id <= entryCount; id++) _galleryEntry(id),
  ];
  EntriesProvider.instance.filter = const GalleryFilter();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: EntriesProvider.instance),
      ChangeNotifierProvider.value(value: EntryAttachmentsProvider.instance),
      ChangeNotifierProvider.value(value: TagsProvider.instance),
      ChangeNotifierProvider.value(value: MoodScaleProvider.instance),
      ChangeNotifierProvider.value(value: ConfigProvider.instance),
      ChangeNotifierProvider.value(value: GallerySelection.instance),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...appLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: const GallerySelectionBar(),
        body: const GalleryPage(),
      ),
    ),
  ));
}

void resetGalleryPageState() {
  GallerySelection.instance.clear();
  EntryStore.instance.entries = [];
  EntriesProvider.instance.filter = const GalleryFilter();
}
