import 'dart:io';

import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class ShareTemplatesDialog extends StatefulWidget {
  const ShareTemplatesDialog({super.key});

  @override
  State<ShareTemplatesDialog> createState() => _ShareTemplatesDialogState();
}

class _ShareTemplatesDialogState extends State<ShareTemplatesDialog> {
  final Set<int> _selectedIds = {};

  String _fileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return "daily_you_templates_$timestamp.json";
  }

  Future<void> _showErrorDialog(String description) async {
    if (!mounted) return;
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(AppLocalizations.of(context)!.errorTitle),
              actions: [
                TextButton(
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              ],
              content: Text(description));
        });
  }

  Future<void> _save() async {
    final bytes = TemplatesTagsTransfer.exportTemplates(_selectedIds);
    final fileName = _fileName();

    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");
    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    final success =
        await TemplatesTagsTransfer.saveBytesToFile(bytes, fileName, (status) {
      statusNotifier.value = status;
    });

    if (!mounted) return;
    Navigator.of(context).pop();

    if (!success) {
      await _showErrorDialog(
          AppLocalizations.of(context)!.exportErrorDescription);
    }
  }

  Future<void> _share() async {
    final bytes = TemplatesTagsTransfer.exportTemplates(_selectedIds);
    await TemplatesTagsTransfer.shareBytes(bytes, _fileName());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templates = Provider.of<TemplatesProvider>(context).templates;
    final allIds = templates.map((template) => template.id!).toSet();
    final hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareButtonLabel),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all_rounded),
            onPressed: () => setState(() => _selectedIds.addAll(allIds)),
          ),
          IconButton(
            icon: const Icon(Icons.deselect_rounded),
            onPressed: () => setState(() => _selectedIds.clear()),
          ),
        ],
      ),
      body: templates.isEmpty
          ? Center(child: Text(l10n.noTemplatesDescription))
          : ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return CheckboxListTile(
                  title: Text(template.name, overflow: TextOverflow.ellipsis),
                  value: _selectedIds.contains(template.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _selectedIds.add(template.id!);
                      } else {
                        _selectedIds.remove(template.id);
                      }
                    });
                  },
                );
              },
            ),
      bottomNavigationBar: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.save_alt_rounded),
                    label:
                        Text(MaterialLocalizations.of(context).saveButtonLabel),
                    onPressed: hasSelection ? _save : null,
                  ),
                ),
                if (Platform.isAndroid) const SizedBox(width: 12),
                if (Platform.isAndroid)
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share_rounded),
                      label: Text(l10n.shareButtonLabel),
                      onPressed: hasSelection ? _share : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
