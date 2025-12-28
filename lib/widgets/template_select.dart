import 'package:daily_you/models/template.dart';
import 'package:daily_you/providers/templates_provider.dart';
import 'package:daily_you/widgets/template_manager.dart';
import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class TemplateSelect extends StatelessWidget {
  final Function(Template template) onTemplatesSelected;

  const TemplateSelect({super.key, required this.onTemplatesSelected});

  void _showTemplateManagementPopup(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
        allowSnapshotting: false,
        fullscreenDialog: true,
        builder: (context) => TemplateManager()));
  }

  Widget _buildTemplatesList(BuildContext context) {
    final templatesProvider = Provider.of<TemplatesProvider>(context);
    final templates = templatesProvider.templates;

    if (templates.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context)!.noTemplatesDescription),
        ],
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return ListTile(
            title: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                template.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            trailing: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Icon(Icons.add_rounded),
            ),
            onTap: () {
              onTemplatesSelected(template);
              Navigator.of(context).pop();
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addTemplate),
      content: SizedBox(
          width: double.maxFinite, child: _buildTemplatesList(context)),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.edit_document),
          label: Text(AppLocalizations.of(context)!.manageTemplates),
          onPressed: () {
            _showTemplateManagementPopup(context);
          },
        ),
        TextButton(
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
