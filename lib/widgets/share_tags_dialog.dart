import 'dart:io';

import 'package:daily_you/providers/tags_provider.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/tag_category_visuals.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:daily_you/widgets/tag_icon_glyph.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class ShareTagsDialog extends StatefulWidget {
  const ShareTagsDialog({super.key});

  @override
  State<ShareTagsDialog> createState() => _ShareTagsDialogState();
}

class _ShareTagsDialogState extends State<ShareTagsDialog> {
  final Set<int> _selectedTagIds = {};

  String _fileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return "daily_you_tags_$timestamp.json";
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
    final bytes = TemplatesTagsTransfer.exportTags(_selectedTagIds);
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
    final bytes = TemplatesTagsTransfer.exportTags(_selectedTagIds);
    await TemplatesTagsTransfer.shareBytes(bytes, _fileName());
  }

  bool? _sectionCheckboxValue(TagSection section) {
    final ids = section.tags.map((tag) => tag.id).toSet();
    final selectedCount = ids.where(_selectedTagIds.contains).length;
    if (selectedCount == 0) return false;
    if (selectedCount == ids.length) return true;
    return null;
  }

  void _toggleSection(TagSection section) {
    final ids = section.tags.map((tag) => tag.id!).toList();
    final allSelected = ids.every(_selectedTagIds.contains);
    setState(() {
      if (allSelected) {
        _selectedTagIds.removeAll(ids);
      } else {
        _selectedTagIds.addAll(ids);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<TagsProvider>(context);
    final sections = provider.buildSections("");
    final allIds = provider.tags.map((tag) => tag.id!).toSet();
    final hasSelection = _selectedTagIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shareButtonLabel),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all_rounded),
            onPressed: () => setState(() => _selectedTagIds.addAll(allIds)),
          ),
          IconButton(
            icon: const Icon(Icons.deselect_rounded),
            onPressed: () => setState(() => _selectedTagIds.clear()),
          ),
        ],
      ),
      body: sections.isEmpty
          ? Center(child: Text(l10n.noResults))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 8.0),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final category = section.category;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.only(left: 16, right: 8),
                      tristate: true,
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      value: _sectionCheckboxValue(section),
                      onChanged: (_) => _toggleSection(section),
                      title: Row(
                        children: [
                          if (category != null) ...[
                            TagIconGlyph(
                              icon: category.icon,
                              iconType: category.iconType,
                              fallbackIcon: Icons.folder_rounded,
                              color: category.resolvedColor(context),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            category?.name ?? l10n.tagCategoryUncategorized,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    for (final tag in section.tags)
                      CheckboxListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 32.0, right: 24.0),
                        title: Text(tag.name, overflow: TextOverflow.ellipsis),
                        value: _selectedTagIds.contains(tag.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked ?? false) {
                              _selectedTagIds.add(tag.id!);
                            } else {
                              _selectedTagIds.remove(tag.id);
                            }
                          });
                        },
                      ),
                  ],
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
