// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'dart:io';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/database/app_database.dart';
import 'package:daily_you/database/attachment_storage.dart';
import 'package:daily_you/models/attachment.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/utils/file_size_format.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/attachment_type_presentation.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/file_size_row.dart';
import 'package:daily_you/widgets/media_quality_dialog.dart';
import 'package:daily_you/widgets/settings_header.dart';
import 'package:daily_you/widgets/settings_icon_action.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class StorageSettings extends StatefulWidget {
  const StorageSettings({super.key});

  @override
  State<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends State<StorageSettings> {
  late Map<AttachmentType, Future<int>> _usage;

  @override
  void initState() {
    super.initState();
    _usage = _loadUsage();
  }

  Map<AttachmentType, Future<int>> _loadUsage() => {
        for (final type in AttachmentType.values)
          type: AttachmentStorage.instance.internalSizeBytes(type),
      };

  void _refreshUsage() {
    if (mounted) setState(() => _usage = _loadUsage());
  }

  Future<bool> requestStoragePermission() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    if (androidInfo.version.sdkInt < 33) {
      //Legacy Permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        return true;
      }
      return false;
    }

    //Modern Permission
    return true;
  }

  Future<bool> requestPhotosPermission() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    if (androidInfo.version.sdkInt < 33) {
      //Legacy Permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        return true;
      }
      return false;
    } else {
      //Modern Photos Permission
      return true;
    }
  }

  Future<void> _showChangeLogFolderWarning() async {
    bool confirmed = false;
    await showAppDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.warningTitle),
          content:
              Text(AppLocalizations.of(context)!.logFolderWarningDescription),
          actions: [
            TextButton(
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
              onPressed: () async {
                confirmed = true;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    if (confirmed) {
      if (!mounted) return;
      ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

      BackupRestoreUtils.showLoadingStatus(context, statusNotifier);
      final outcome =
          await AppDatabase.instance.selectExternalLocation((status) {
        statusNotifier.value = status;
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      if (outcome.failed) {
        await showFailureDialog(context,
            description:
                AppLocalizations.of(context)!.logFolderErrorDescription,
            error: outcome.error);
      }
    }
  }

  Future<void> _attemptImageFolderChange() async {
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);
    final outcome =
        await AttachmentStorage.instance.selectExternalLocation((status) {
      statusNotifier.value = status;
    });

    if (!mounted) return;
    Navigator.of(context).pop();
    _refreshUsage();

    if (outcome.failed) {
      await showFailureDialog(context,
          description:
              AppLocalizations.of(context)!.imageFolderErrorDescription,
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
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    try {
      await EntriesProvider.instance.deleteAll((status) {
        statusNotifier.value = status;
      });

      await AttachmentStorage.instance.garbageCollectAttachments();
    } finally {
      if (context.mounted) Navigator.of(context).pop();
      _refreshUsage();
    }
  }

  String _formatBytes(int bytes) =>
      formatFileSize(bytes, AppLocalizations.of(context)!.localeName);

  Widget _storageUsageRow(IconData icon, String label, Future<int> usage) {
    return FutureBuilder<int>(
      future: usage,
      builder: (context, snapshot) {
        final sizeText = snapshot.hasData ? _formatBytes(snapshot.data!) : '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: FileSizeRow(icon: icon, label: label, sizeText: sizeText),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsStorageTitle),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          FutureBuilder(
              future: AppDatabase.instance.getInternalPath(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  var folderText = snapshot.data!;
                  if (AppDatabase.instance.usingExternalLocation()) {
                    folderText = StoragePicker.displayName(
                        configProvider.get(Settings.externalDbUri));
                  }
                  return SettingsIconAction(
                    title: AppLocalizations.of(context)!.settingsLogFolder,
                    hint: folderText,
                    icon: Icon(Icons.folder_rounded),
                    secondaryIcon: Icon(Icons.refresh_rounded),
                    onPressed: () async {
                      if (Platform.isAndroid &&
                          !await requestStoragePermission()) {
                        return;
                      }
                      await _showChangeLogFolderWarning();
                    },
                    onSecondaryPressed: () async {
                      await AppDatabase.instance.resetExternalLocation();
                    },
                  );
                }
                return const SizedBox();
              }),
          FutureBuilder(
              future: AttachmentStorage.instance
                  .getInternalFolder(AttachmentType.image),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  var folderText = snapshot.data!;
                  if (AttachmentStorage.instance.usingExternalLocation()) {
                    folderText = StoragePicker.displayName(
                        configProvider.get(Settings.externalImgUri));
                  }
                  return SettingsIconAction(
                    title: AppLocalizations.of(context)!.settingsImageFolder,
                    hint: folderText,
                    icon: Icon(Icons.folder_rounded),
                    secondaryIcon: Icon(Icons.refresh_rounded),
                    onPressed: () async {
                      if (Platform.isAndroid &&
                          !await requestPhotosPermission()) {
                        return;
                      }
                      await _attemptImageFolderChange();
                    },
                    onSecondaryPressed: () async {
                      await AttachmentStorage.instance
                          .resetImageFolderLocation();
                    },
                  );
                }
                return const SizedBox();
              }),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
            child: SettingsHeader(text: l10n.settingsStorageUsage),
          ),
          for (final type in AttachmentType.values)
            _storageUsageRow(type.icon, type.label(l10n), _usage[type]!),
          SettingsIconAction(
            title: l10n.settingsMediaQualityTitle,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => showAppDialog(
                context: context, builder: (_) => const MediaQualityDialog()),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, right: 8.0),
            child: Divider(),
          ),
          SettingsIconAction(
              title: AppLocalizations.of(context)!.settingsDeleteAllLogsTitle,
              icon: Icon(Icons.delete_forever_rounded),
              onPressed: () => _showDeleteAllLogsDialog(
                  context,
                  AppLocalizations.of(context)!.settingsDeleteAllLogsTitle,
                  () => _deleteAllLogs(context))),
        ],
      ),
    );
  }
}
