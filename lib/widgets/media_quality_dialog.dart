// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/settings_dropdown.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class MediaQualityDialog extends StatelessWidget {
  const MediaQualityDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ConfigProvider>(
      builder: (context, config, _) => AlertDialog(
        title: Text(l10n.settingsMediaQualityTitle),
        contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qualityRow(config, AttachmentType.image.label(l10n),
                Settings.imageQualityLevel, [
              (ImageQuality.noCompression, l10n.imageQualityNoCompression),
              (ImageQuality.high, l10n.imageQualityHigh),
              (ImageQuality.medium, l10n.imageQualityMedium),
              (ImageQuality.low, l10n.imageQualityLow),
            ]),
            if (Platform.isAndroid)
              _qualityRow(config, AttachmentType.video.label(l10n),
                  Settings.videoQualityLevel, [
                (VideoQuality.noCompression, l10n.imageQualityNoCompression),
                (VideoQuality.high, l10n.imageQualityHigh),
                (VideoQuality.medium, l10n.imageQualityMedium),
                (VideoQuality.low, l10n.imageQualityLow),
              ]),
            _qualityRow(config, AttachmentType.audio.label(l10n),
                Settings.audioQualityLevel, [
              (AudioQuality.high, l10n.imageQualityHigh),
              (AudioQuality.medium, l10n.imageQualityMedium),
              (AudioQuality.low, l10n.imageQualityLow),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  Widget _qualityRow(ConfigProvider config, String title,
      Setting<String> setting, List<(String, String)> options) {
    return SettingsDropdown<String>(
      title: title,
      expanded: true,
      value: config.get(setting),
      options: [
        for (final (value, label) in options)
          DropdownMenuItem<String>(value: value, child: Text(label)),
      ],
      selectedItemBuilder: (context) => [
        for (final (_, label) in options)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(label,
                maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
          ),
      ],
      onChanged: (String? newValue) {
        if (newValue != null) config.set(setting, newValue);
      },
    );
  }
}
