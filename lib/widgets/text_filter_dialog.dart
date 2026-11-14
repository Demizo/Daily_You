// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/gallery_filter.dart';
import 'package:daily_you/providers/entries_provider.dart';
import 'package:daily_you/widgets/gallery_filter_dialog.dart';
import 'package:daily_you/widgets/filter_pill.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class TextFilterDialog extends StatefulWidget {
  const TextFilterDialog({super.key});

  @override
  State<TextFilterDialog> createState() => _TextFilterDialogState();
}

class _TextFilterDialogState extends State<TextFilterDialog> {
  final TextEditingController _termController = TextEditingController();
  final FocusNode _termFocusNode = FocusNode();

  @override
  void dispose() {
    _termController.dispose();
    _termFocusNode.dispose();
    super.dispose();
  }

  void _addTerm(EntriesProvider provider) {
    _commitTerm(provider);
    _termFocusNode.requestFocus();
  }

  void _commitTerm(EntriesProvider provider) {
    final term = _termController.text.trim();
    _termController.clear();
    final filter = provider.filter;
    if (term.isEmpty || filter.noText) return;
    if (filter.textTerms.contains(term)) return;
    provider.filter = filter.copyWith(textTerms: [...filter.textTerms, term]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<EntriesProvider>();
    final filter = provider.filter;

    return GalleryFilterDialog(
      title: l10n.filterPillKeywords,
      canClear: filter.hasText || filter.textMatchCase,
      onClear: () => provider.filter = filter.withoutText(),
      onShowLogs: () => _commitTerm(provider),
      noneLabel: l10n.noTextFilterLabel,
      noneValue: filter.noText,
      onNoneChanged: (value) {
        if (value) _termFocusNode.unfocus();
        provider.filter = filter.copyWith(
          noText: value,
          textTerms: value ? const [] : filter.textTerms,
        );
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _termController,
                  focusNode: _termFocusNode,
                  hintText: l10n.keywordFilterHint,
                  elevation: const WidgetStatePropertyAll(0),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerLowest,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTerm(provider),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                onPressed: () => _addTerm(provider),
                color: colorScheme.onPrimary,
                tooltip: l10n.keywordFilterHint,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (filter.textTerms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in filter.textTerms)
                  FilterPill(
                    backgroundColor: colorScheme.surfaceContainerLowest,
                    foregroundColor: colorScheme.onSurface,
                    onClear: () => provider.filter = filter.copyWith(
                      textTerms: [...filter.textTerms]..remove(term),
                    ),
                    child: Text(term),
                  ),
              ],
            ),
          ],
          if (filter.textTerms.length > 1) ...[
            const SizedBox(height: 12),
            SegmentedButton<TextTermJoin>(
              segments: [
                ButtonSegment(
                  value: TextTermJoin.all,
                  label: Text(l10n.keywordFilterMatchAll),
                ),
                ButtonSegment(
                  value: TextTermJoin.any,
                  label: Text(l10n.keywordFilterMatchAny),
                ),
              ],
              selected: {filter.textJoin},
              onSelectionChanged: (selected) =>
                  provider.filter = filter.copyWith(textJoin: selected.first),
            ),
          ],
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.keywordFilterMatchCase),
            value: filter.textMatchCase,
            onChanged: (value) => provider.filter =
                filter.copyWith(textMatchCase: value ?? false),
          ),
        ],
      ),
    );
  }
}
