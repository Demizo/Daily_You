// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/storage/external_sync_settings.dart';
import 'package:daily_you/storage/storage_picker.dart';
import 'package:daily_you/storage/sync_item.dart';
import 'package:daily_you/widgets/database_overwrite_dialog.dart';
import 'package:daily_you/widgets/sync_item_presentation.dart';
import 'package:material_ui/material_ui.dart';

class ExternalSyncDialog extends StatefulWidget {
  const ExternalSyncDialog({
    super.key,
    required this.initial,
    this.draft,
    this.pickDirectory,
    this.hasDatabase,
  });

  final ExternalSyncSettings initial;

  final ExternalSyncSettings? draft;

  final Future<String?> Function()? pickDirectory;

  final Future<bool> Function(String uri)? hasDatabase;

  @override
  State<ExternalSyncDialog> createState() => _ExternalSyncDialogState();
}

class _ExternalSyncDialogState extends State<ExternalSyncDialog> {
  late ExternalSyncSettings _draft = widget.draft ?? widget.initial;

  Future<String?> _pickDirectory() async {
    final pick = widget.pickDirectory;
    if (pick != null) return pick();
    return (await StoragePicker.pickDirectoryWithAccess())?.uri;
  }

  Future<void> _change(SyncItem item, SyncChoice choice) async {
    final next = _draft.withChoice(item, choice);
    final logsLocation = next.location(SyncItem.logs);
    if (item == SyncItem.logs &&
        logsLocation != null &&
        logsLocation != widget.initial.location(SyncItem.logs) &&
        !await confirmDatabaseOverwrite(context, logsLocation.uri,
            hasDatabase: widget.hasDatabase)) {
      return;
    }
    if (mounted) setState(() => _draft = next);
  }

  Future<void> _pick(SyncItem item) async {
    final uri = await _pickDirectory();
    if (uri != null) await _change(item, _draft.choice(item).withFolder(uri));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canConfirm = _draft != widget.initial && _draft.isOn;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final item in SyncItem.values) _row(l10n, item)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: canConfirm ? () => Navigator.pop(context, _draft) : null,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, SyncItem item) {
    final choice = _draft.choice(item);
    final destination = _draft.destination(item);
    return _SyncFolderRow(
      title: item.label(l10n),
      subtitle:
          destination == null ? l10n.chooseFolderHint : _describe(destination),
      dimmed: !choice.enabled,
      toggle: destination != null ? choice.enabled : null,
      onToggle: (value) => _change(item, choice.withEnabled(value)),
      onPick: () => _pick(item),
      onReset: item != SyncItem.logs &&
              _draft.logFolderUri != null &&
              choice.folderUri != null
          ? () => _change(item, choice.withFolder(null))
          : null,
    );
  }

  String _describe(SyncLocation location) {
    final folder = StoragePicker.displayName(location.uri);
    final subfolder = location.subfolder;
    return subfolder == null ? folder : '$folder/$subfolder';
  }
}

class _SyncFolderRow extends StatelessWidget {
  const _SyncFolderRow({
    required this.title,
    required this.subtitle,
    required this.onPick,
    required this.onToggle,
    this.onReset,
    this.toggle,
    this.dimmed = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPick;
  final VoidCallback? onReset;

  final bool? toggle;
  final ValueChanged<bool> onToggle;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? Theme.of(context).disabledColor : null;
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: color)),
                Text(subtitle, style: TextStyle(fontSize: 14, color: color)),
              ],
            ),
          ),
          if (onReset != null)
            IconButton(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
            ),
          IconButton(
            onPressed: onPick,
            icon: const Icon(Icons.folder_rounded),
          ),
          Visibility(
            visible: toggle != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Switch(value: toggle ?? false, onChanged: onToggle),
          ),
        ],
      ),
    );
  }
}
