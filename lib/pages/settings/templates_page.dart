import 'package:daily_you/models/template.dart';
import 'package:daily_you/utils/backup_restore_utils.dart';
import 'package:daily_you/utils/templates_tags_transfer.dart';
import 'package:daily_you/widgets/edit_template.dart';
import 'package:daily_you/widgets/share_templates_dialog.dart';
import 'package:flutter/material.dart';
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
    ValueNotifier<String> statusNotifier = ValueNotifier<String>("");

    BackupRestoreUtils.showLoadingStatus(context, statusNotifier);

    bool success = await TemplatesTagsTransfer.importTransferFile((status) {
      statusNotifier.value = status;
    });

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (!success) {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(AppLocalizations.of(context)!.errorTitle),
                actions: [
                  TextButton(
                    child:
                        Text(MaterialLocalizations.of(context).okButtonLabel),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ],
                content:
                    Text(AppLocalizations.of(context)!.importErrorDescription));
          });
    }
  }

  Widget _templateList(BuildContext context) {
    final templatesProvider = Provider.of<TemplatesProvider>(context);
    final configProvider = Provider.of<ConfigProvider>(context);
    final templates = templatesProvider.templates;
    final defaultTemplateId =
        configProvider.get(ConfigKey.defaultTemplate) as int?;

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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final isDefault = defaultTemplateId == template.id;
        return ListTile(
          title: Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16, top: 8.0, bottom: 8.0),
            child: Text(
              template.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
                onPressed: () async {
                  await configProvider.set(
                      ConfigKey.defaultTemplate, isDefault ? -1 : template.id);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTemplatesTitle),
        centerTitle: true,
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _templateList(context),
            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditTemplatePopup(context, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
