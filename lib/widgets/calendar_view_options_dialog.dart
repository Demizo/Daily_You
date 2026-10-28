// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/settings_dialog.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/tag_chip.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Future<void> showCalendarViewOptionsDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showSettingsDialog(
    context: context,
    builder: (dialogContext) {
      final configProvider = ConfigProvider.instance;
      final tagsProvider = Provider.of<TagsProvider>(dialogContext);
      final overlayTagId = configProvider.get(Settings.calendarTagOverlay);
      final overlayTag = overlayTagId == null
          ? null
          : tagsProvider.tags
              .where((tag) => tag.id == overlayTagId)
              .firstOrNull;
      return [
        SettingsToggleRow(
          icon: Icons.image_rounded,
          title: l10n.imagesTitle,
          value: !configProvider.get(Settings.hideImagesInCalendar),
          onChanged: (value) =>
              configProvider.set(Settings.hideImagesInCalendar, !value),
        ),
        SettingsToggleRow.setting(
          icon: Icons.mood_rounded,
          title: l10n.tagMoodTitle,
          setting: Settings.calendarShowMood,
        ),
        _tagDisplayRow(context, l10n, configProvider, overlayTag),
      ];
    },
  );
}

Widget _tagDisplayRow(
  BuildContext context,
  AppLocalizations l10n,
  ConfigProvider configProvider,
  Tag? overlayTag,
) {
  final currentValue = overlayTag == null
      ? 'none'
      : overlayTag.tagType == TagType.tracker
          ? 'tracker'
          : 'label';

  return SettingsChoiceRow<String>(
    icon: Icons.local_offer_rounded,
    title: l10n.calendarTagDisplayLabel,
    value: currentValue,
    options: {
      'none': l10n.noTemplateTitle,
      'label': l10n.tagTypeLabelTitle,
      'tracker': l10n.tagTypeTrackerTitle,
    },
    accessoryBuilder: (option) => option == currentValue && overlayTag != null
        ? TagChip(tag: overlayTag)
        : null,
    onChanged: (value) async {
      if (value == 'none') {
        configProvider.set(Settings.calendarTagOverlay, null);
        return;
      }
      final filter = value == 'tracker' ? TagType.tracker : TagType.label;
      final tag = await showAppDialog<Tag>(
        context: context,
        builder: (_) => TagPickerDialog(
          mode: TagPickerMode.selectSingle,
          tagTypeFilter: filter,
        ),
      );
      if (tag != null) {
        configProvider.set(Settings.calendarTagOverlay, tag.id);
      }
    },
  );
}
