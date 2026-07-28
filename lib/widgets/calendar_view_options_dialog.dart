import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/tag.dart';
import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:daily_you/widgets/tag_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarViewOptionsDialog extends StatelessWidget {
  const CalendarViewOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<ConfigProvider, TagsProvider>(
      builder: (context, config, tagsProvider, _) {
        final showImages = config.get(ConfigKey.hideImagesInCalendar) != true;
        final showMood = config.get(ConfigKey.calendarShowMood) != false;
        final overlayTagId = config.get(ConfigKey.calendarTagOverlay) as int?;
        final overlayTag = overlayTagId != null
            ? tagsProvider.tags
                .where((tag) => tag.id == overlayTagId)
                .firstOrNull
            : null;

        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.image_rounded),
                title: Text(l10n.imagesTitle),
                value: showImages,
                onChanged: (value) =>
                    config.set(ConfigKey.hideImagesInCalendar, !value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.mood_rounded),
                title: Text(l10n.tagMoodTitle),
                value: showMood,
                onChanged: (value) =>
                    config.set(ConfigKey.calendarShowMood, value),
              ),
              _buildTagDisplayRow(context, l10n, config, overlayTag),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownValueText(String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
  }

  Widget _buildTagDisplayRow(
    BuildContext context,
    AppLocalizations l10n,
    ConfigProvider config,
    Tag? overlayTag,
  ) {
    final currentValue = overlayTag == null
        ? 'none'
        : overlayTag.tagType == TagType.tracker
            ? 'tracker'
            : 'label';

    return SettingsDropdown<String>(
      title: l10n.calendarTagDisplayLabel,
      leadingIcon: Icons.local_offer_rounded,
      value: currentValue,
      options: [
        DropdownMenuItem(value: 'none', child: Text(l10n.noTemplateTitle)),
        DropdownMenuItem(value: 'label', child: Text(l10n.tagTypeLabelTitle)),
        DropdownMenuItem(
            value: 'tracker', child: Text(l10n.tagTypeTrackerTitle)),
      ],
      selectedItemBuilder: (context) => [
        Text(l10n.noTemplateTitle),
        _buildDropdownValueText(overlayTag?.name ?? l10n.tagTypeLabelTitle),
        _buildDropdownValueText(overlayTag?.name ?? l10n.tagTypeTrackerTitle),
      ],
      onChanged: (value) async {
        if (value == null) return;
        if (value == 'none') {
          config.set(ConfigKey.calendarTagOverlay, null);
          return;
        }
        final filter = value == 'tracker' ? TagType.tracker : TagType.label;
        final tag = await showDialog<Tag>(
          context: context,
          builder: (_) => TagPickerDialog(
            mode: TagPickerMode.selectSingle,
            tagTypeFilter: filter,
          ),
        );
        if (tag != null) {
          config.set(ConfigKey.calendarTagOverlay, tag.id);
        }
      },
    );
  }
}
