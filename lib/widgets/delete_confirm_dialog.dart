import 'package:flutter/material.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';

/// Delete confirmation prompt. Returns true when a delete is confirmed, false otherwise.
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AppLocalizations.of(dialogContext)!.deleteTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child:
              Text(MaterialLocalizations.of(dialogContext).deleteButtonTooltip),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child:
              Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
