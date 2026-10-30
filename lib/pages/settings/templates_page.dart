// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/models/template.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:daily_you/widgets/failure_dialog.dart';
import 'package:daily_you/widgets/share_templates_dialog.dart';
import 'package:daily_you/widgets/segmented_group.dart';
import 'package:daily_you/widgets/settings_page_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TemplateSettings extends StatefulWidget {
  const TemplateSettings({super.key});

  @override
  State<TemplateSettings> createState() => _TemplateSettingsState();
}

class _TemplateSettingsState extends State<TemplateSettings> {
  void _showEditTemplatePopup(BuildContext context, Template? template) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => EditTemplate(template: template)));
  }

  void _showShareDialog(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => const ShareTemplatesDialog()));
  }

  Future<void> _importFile(BuildContext context) async {
    final outcome = await BackupRestoreUtils.runWithLoadingStatus(
        context, TemplatesTagsTransfer.importTransferFile);

    if (!context.mounted) return;

    if (outcome.failed) {
      await showFailureDialog(context,
          description: AppLocalizations.of(context)!.importErrorDescription,
          error: outcome.error);
    }
  }

  Widget _templateList(BuildContext context) {
    final templatesProvider = Provider.of<TemplatesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final templates = templatesProvider.templates;
    final defaultTemplateId = configProvider.get(Settings.defaultTemplate);

    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.noTemplatesDescription),
          ],
        ),
      );
    }

    return SegmentedGroup(children: [
      for (final template in templates)
        _templateRow(context, template, defaultTemplateId == template.id),
    ]);
  }

  Widget _templateRow(BuildContext context, Template template, bool isDefault) {
    return ListTile(
      title: Text(
        template.name,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
            ),
            onPressed: () async {
              await ConfigProvider.instance
                  .set(Settings.defaultTemplate, isDefault ? -1 : template.id!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditTemplatePopup(context, template),
          ),
        ],
      ),
      onTap: () => _showEditTemplatePopup(context, template),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsPageScaffold(
      title: l10n.settingsTemplatesTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.file_open_outlined),
          onPressed: () => _importFile(context),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () => _showShareDialog(context),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditTemplatePopup(context, null),
        child: const Icon(Icons.add_rounded),
      ),
      children: [_templateList(context)],
    );
  }
}
