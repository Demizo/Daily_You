// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/storage/external_sync.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/storage/sync_progress.dart';
import 'package:daily_you/utils/file_size_format.dart';
import 'package:daily_you/utils/operation_outcome.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/database_overwrite_dialog.dart';
import 'package:daily_you/widgets/external_sync_dialog.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_rows.dart';
import 'package:daily_you/widgets/sync_progress_dialog.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class StorageSettings extends StatefulWidget {
  const StorageSettings({super.key});

  @override
  State<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends State<StorageSettings> {
  late Future<Map<AttachmentType, int>> _usage;

  @override
  void initState() {
    super.initState();
    _usage = _loadUsage();
  }

  Future<Map<AttachmentType, int>> _loadUsage() async {
    final sizes = await Future.wait([
      for (final type in AttachmentType.values)
        AttachmentStorage.instance.internalSizeBytes(type),
    ]);
    return Map.fromIterables(AttachmentType.values, sizes);
  }

  void _refreshUsage() {
    if (mounted) setState(() => _usage = _loadUsage());
  }

  Future<void> _editSync({ExternalSyncSettings? draft}) async {
    final saved = ExternalSyncSettings.load();
    final desired = await showAppDialog<ExternalSyncSettings>(
        context: context,
        builder: (_) => ExternalSyncDialog(initial: saved, draft: draft));
    if (desired != null && mounted) await _applySync(saved, desired);
  }

  Future<void> _toggleSync(bool enabled) async {
    if (!enabled) {
      await _applySync(
          ExternalSyncSettings.load(), const ExternalSyncSettings());
      return;
    }

    final uri = (await StoragePicker.pickDirectoryWithAccess())?.uri;
    if (uri == null || !mounted) return;
    if (!await confirmDatabaseOverwrite(context, uri)) return;
    if (!mounted) return;
    await _editSync(draft: ExternalSyncSettings.withDefaults(uri));
  }

  Future<void> _applySync(
      ExternalSyncSettings saved, ExternalSyncSettings desired) async {
    final sync = ExternalSync(saved, desired);
    if (!sync.hasWork) {
      await sync.run((_) {});
      return;
    }

    final navigator = Navigator.of(context);
    final progress = ValueNotifier(SyncProgress(sync.items.first));
    showSyncProgressDialog(context, progress);
    final OperationOutcome outcome;
    try {
      outcome = await sync.run((value) => progress.value = value);
    } finally {
      navigator.pop();
    }
    if (!mounted) return;
    _refreshUsage();

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.syncErrorDescription,
          error: outcome.error);
    }
  }

  void _showDeleteAllLogsDialog(
      BuildContext context, String requiredText, VoidCallback onConfirm) {
    ThemeData theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

    showAppDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.settingsDeleteAllLogsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!
                  .settingsDeleteAllLogsDescription),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(AppLocalizations.of(context)!
                    .settingsDeleteAllLogsPrompt(requiredText)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                          hintStyle: TextStyle(fontStyle: FontStyle.italic),
                          hintText: requiredText,
                          border: InputBorder.none),
                      controller: controller,
                      onChanged: (value) {
                        isButtonEnabled.value = value.toLowerCase().trim() ==
                            requiredText.toLowerCase().trim();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isButtonEnabled,
              builder: (context, isEnabled, child) {
                return TextButton(
                  onPressed: isEnabled
                      ? () {
                          Navigator.of(context).pop();
                          onConfirm();
                        }
                      : null,
                  child: Text(
                      style: TextStyle(
                          color: isEnabled ? null : theme.disabledColor),
                      MaterialLocalizations.of(context).deleteButtonTooltip),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllLogs(BuildContext context) async {
    try {
      await BackupRestoreUtils.runWithLoadingStatus(context,
          (updateStatus) async {
        await EntriesProvider.instance.deleteAll(updateStatus);
        await AttachmentStorage.instance.garbageCollectAttachments();
      });
    } finally {
      _refreshUsage();
    }
  }

  static final List<AttachmentType> _mediaQualityTypes = [
    for (final type in AttachmentType.values)
      if (type != AttachmentType.video || Platform.isAndroid) type,
  ];

  List<Widget> _mediaQualityOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configProvider = ConfigProvider.instance;
    return [
      for (final type in _mediaQualityTypes)
        SettingsChoiceRow<String>(
          title: type.label(l10n),
          value: configProvider.get(type.qualitySetting),
          options: type.qualityLabels(l10n),
          onChanged: (value) => configProvider.set(type.qualitySetting, value),
        ),
    ];
  }

  Widget _storageUsageRow(AppLocalizations l10n) {
    String format(int bytes) => formatFileSize(bytes, l10n.localeName);
    return FutureBuilder<Map<AttachmentType, int>>(
      future: _usage,
      builder: (context, snapshot) {
        final sizes = snapshot.data;
        return SettingsInfoRow(
          icon: Icons.pie_chart_rounded,
          title: l10n.settingsStorageUsage,
          subtitle: _UsageChips(entries: [
            for (final type in AttachmentType.values)
              (
                label: type.label(l10n),
                size: sizes == null ? null : format(sizes[type] ?? 0),
              ),
          ]),
          value: sizes == null
              ? null
              : format(sizes.values.fold(0, (total, size) => total + size)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<ConfigProvider>(context);
    final syncSettings = ExternalSyncSettings.load();
    final syncedFolder = syncSettings.logFolderUri;

    return SettingsPageScaffold(
      title: l10n.settingsStorageTitle,
      children: [
        SegmentedGroup(children: [
          SettingsToggleRow(
            icon: Icons.sync_rounded,
            title: l10n.settingsExternalSyncTitle,
            subtitle: syncedFolder == null
                ? null
                : StoragePicker.displayName(syncedFolder),
            value: syncSettings.isOn,
            onChanged: _toggleSync,
            onOpenOptions: _editSync,
          ),
        ]),
        SegmentedGroup(children: [
          _storageUsageRow(l10n),
          SettingsDialogRow(
            icon: Icons.high_quality_rounded,
            title: l10n.settingsMediaQualityTitle,
            options: _mediaQualityOptions,
          ),
        ]),
        SegmentedGroup(children: [
          SettingsActionRow(
            icon: Icons.delete_forever_rounded,
            title: l10n.settingsDeleteAllLogsTitle,
            destructive: true,
            onTap: () => _showDeleteAllLogsDialog(context,
                l10n.settingsDeleteAllLogsTitle, () => _deleteAllLogs(context)),
          ),
        ]),
      ],
    );
  }
}

class _UsageChips extends StatelessWidget {
  const _UsageChips({required this.entries});

  final List<({String label, String? size})> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (:label, :size) in entries)
            Chip(
              label: size == null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [Text(label), const _SizePlaceholder()],
                    )
                  : Text('$label $size'),
              labelStyle: theme.textTheme.labelMedium,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }
}

class _SizePlaceholder extends StatelessWidget {
  const _SizePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 10,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
