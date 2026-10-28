// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:material_ui/material_ui.dart';

typedef SettingsRowsBuilder = List<Widget> Function(BuildContext context);

const double settingsDialogRowInset = 8;

Future<T?> showSettingsDialog<T>({
  required BuildContext context,
  String? title,
  required SettingsRowsBuilder builder,
  bool isSelection = false,
  SettingsRowsBuilder? actions,
}) {
  assert(!isSelection || actions == null);
  return showAppDialog<T>(
    context: context,
    builder: (context) => _SettingsDialog(
      title: title,
      builder: builder,
      actions: isSelection
          ? const []
          : actions?.call(context) ??
              [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      Text(MaterialLocalizations.of(context).closeButtonLabel),
                ),
              ],
    ),
  );
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog({
    required this.title,
    required this.builder,
    required this.actions,
  });

  final String? title;
  final SettingsRowsBuilder builder;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(title!,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  settingsDialogRowInset,
                  title == null ? 16 : 0,
                  settingsDialogRowInset,
                  0,
                ),
                child: ListenableBuilder(
                  listenable: ConfigProvider.instance,
                  builder: (context, _) => Column(children: builder(context)),
                ),
              ),
            ),
            if (actions.isEmpty)
              const SizedBox(height: 16)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
