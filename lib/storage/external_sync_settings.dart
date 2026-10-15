// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/storage/sync_item.dart';

typedef SyncLocation = ({String uri, String? subfolder});

class SyncChoice {
  const SyncChoice({this.enabled = false, this.folderUri});

  final bool enabled;

  final String? folderUri;

  SyncChoice withEnabled(bool enabled) =>
      SyncChoice(enabled: enabled, folderUri: folderUri);

  SyncChoice withFolder(String? folderUri) =>
      SyncChoice(enabled: folderUri != null || enabled, folderUri: folderUri);

  @override
  bool operator ==(Object other) =>
      other is SyncChoice &&
      other.enabled == enabled &&
      other.folderUri == folderUri;

  @override
  int get hashCode => Object.hash(enabled, folderUri);
}

class ExternalSyncSettings {
  const ExternalSyncSettings({this.choices = const {}});

  static const items = SyncItem.values;

  factory ExternalSyncSettings.withDefaults(String logFolderUri) =>
      ExternalSyncSettings(
        choices: {
          for (final item in items)
            item: item == SyncItem.logs
                ? SyncChoice(enabled: true, folderUri: logFolderUri)
                : const SyncChoice(enabled: true)
        },
      );

  factory ExternalSyncSettings.load([ConfigProvider? config]) {
    config ??= ConfigProvider.instance;
    final hasLogFolder = config.get(Settings.logSyncFolderUri).isNotEmpty;
    return ExternalSyncSettings(
      choices: {
        for (final item in items) item: _loadChoice(config, item, hasLogFolder),
      },
    );
  }

  static SyncChoice _loadChoice(
      ConfigProvider config, SyncItem item, bool hasLogFolder) {
    final folder = config.get(item.folderSetting);
    final hasLocation = folder.isNotEmpty || hasLogFolder;
    return SyncChoice(
        enabled: config.get(item.syncSetting) && hasLocation,
        folderUri: folder.isEmpty ? null : folder);
  }

  final Map<SyncItem, SyncChoice> choices;

  String? get logFolderUri => choice(SyncItem.logs).folderUri;

  bool get isOn => items.any((item) => location(item) != null);

  SyncChoice choice(SyncItem item) => choices[item] ?? const SyncChoice();

  bool hasLocation(SyncItem item) => destination(item) != null;

  SyncLocation? location(SyncItem item) =>
      choice(item).enabled ? destination(item) : null;

  SyncLocation? destination(SyncItem item) {
    final choice = this.choice(item);
    final customFolder = choice.folderUri;
    if (customFolder != null) return (uri: customFolder, subfolder: null);
    final logFolder = logFolderUri;
    return logFolder == null || item == SyncItem.logs
        ? null
        : (uri: logFolder, subfolder: item.defaultSubfolder);
  }

  ExternalSyncSettings withChoice(SyncItem item, SyncChoice choice) =>
      ExternalSyncSettings(choices: {...choices, item: choice});

  Future<void> save([ConfigProvider? config]) async {
    config ??= ConfigProvider.instance;
    for (final item in items) {
      final choice = this.choice(item);
      await config.set(item.syncSetting, choice.enabled);
      await config.set(item.folderSetting, choice.folderUri ?? '');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ExternalSyncSettings &&
      items.every((item) => other.choice(item) == choice(item));

  @override
  int get hashCode => Object.hashAll([for (final item in items) choice(item)]);
}

extension on SyncItem {
  Setting<bool> get syncSetting => switch (this) {
        SyncItem.logs => Settings.syncLogs,
        SyncItem.images => Settings.syncImages,
        SyncItem.video => Settings.syncVideo,
        SyncItem.audio => Settings.syncAudio,
      };

  Setting<String> get folderSetting => switch (this) {
        SyncItem.logs => Settings.logSyncFolderUri,
        SyncItem.images => Settings.imageSyncFolderUri,
        SyncItem.video => Settings.videoSyncFolderUri,
        SyncItem.audio => Settings.audioSyncFolderUri,
      };
}
