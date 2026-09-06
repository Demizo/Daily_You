import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showFailureDialog(BuildContext context,
    {required String description, Object? error}) {
  return showDialog(
    context: context,
    builder: (context) =>
        FailureDialog(description: description, details: error?.toString()),
  );
}

class FailureDialog extends StatelessWidget {
  const FailureDialog({super.key, required this.description, this.details});

  final String description;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.errorTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            if (details != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: SelectableText(details!),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: details ?? description)),
          child: Text(MaterialLocalizations.of(context).copyButtonLabel),
        ),
        TextButton(
          onPressed: () => launchUrl(
              Uri.https("github.com", "/Demizo/Daily_You/issues"),
              mode: LaunchMode.externalApplication),
          child: Text(AppLocalizations.of(context)!.errorReport),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
