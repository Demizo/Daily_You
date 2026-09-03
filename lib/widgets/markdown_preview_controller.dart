import 'dart:math';

import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/markdown_preview_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A [TextEditingController] that styles Markdown syntax in place
class MarkdownPreviewController extends TextEditingController {
  MarkdownPreviewController({super.text});

  late final SpellCheckService spellCheckService =
      _PreviewSpellCheckService(this);

  String _scannedText = '';
  MarkdownScan _scan = MarkdownScan.empty;
  String _checkedText = '';
  List<SuggestionSpan> _checkedMisspellings = const [];

  MarkdownScan get scan {
    if (_scannedText != text) {
      _scannedText = text;
      _scan = scanMarkdown(text);
    }
    return _scan;
  }

  /// The last spell check result, ranges moved past any edits made since
  List<SuggestionSpan> get misspellings {
    if (_checkedText == text) return _checkedMisspellings;

    final previous = _checkedText;
    final current = text;
    final shortest = min(previous.length, current.length);

    var prefix = 0;
    while (prefix < shortest && previous[prefix] == current[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest - prefix &&
        previous[previous.length - 1 - suffix] ==
            current[current.length - 1 - suffix]) {
      suffix++;
    }

    final editEnd = previous.length - suffix;
    final shift = current.length - previous.length;
    final moved = <SuggestionSpan>[];
    for (final span in _checkedMisspellings) {
      if (span.range.end <= prefix) {
        moved.add(span);
      } else if (span.range.start >= editEnd) {
        moved.add(SuggestionSpan(
          TextRange(
              start: span.range.start + shift, end: span.range.end + shift),
          span.suggestions,
        ));
      }
    }
    return moved
        .where((span) => span.range.end <= current.length)
        .toList(growable: false);
  }

  List<ContextMenuButtonItem> spellCheckMenuItems(EditableTextState editor) {
    final offset = editor.textEditingValue.selection.baseOffset;
    final span = misspellings
        .where((span) => offset >= span.range.start && offset <= span.range.end)
        .firstOrNull;
    if (span == null) return const [];

    return [
      for (final suggestion in span.suggestions.take(3))
        ContextMenuButtonItem(
          label: suggestion,
          onPressed: () {
            editor.hideToolbar();
            editor.userUpdateTextEditingValue(
              TextEditingValue(
                text: text.replaceRange(
                    span.range.start, span.range.end, suggestion),
                selection: TextSelection.collapsed(
                    offset: span.range.start + suggestion.length),
              ),
              SelectionChangedCause.toolbar,
            );
          },
        ),
    ];
  }

  void receiveSpellCheck(String checkedText, List<SuggestionSpan> found) {
    _checkedText = checkedText;
    _checkedMisspellings = found;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      buildMarkdownPreviewSpan(
        text: text,
        spans: scan.spans,
        baseStyle: style ?? const TextStyle(),
        styles: MarkdownPreviewStyles.fromTheme(context),
        composing: withComposing ? value.composing : TextRange.empty,
        misspellings: misspellings.map((span) => span.range).toList(),
      );
}

/// Takes the spell check results and does not pass them along to the framework, this would ruin styling
class _PreviewSpellCheckService implements SpellCheckService {
  _PreviewSpellCheckService(this.controller);

  final MarkdownPreviewController controller;
  final DefaultSpellCheckService _platform = DefaultSpellCheckService();

  @override
  Future<List<SuggestionSpan>?> fetchSpellCheckSuggestions(
      Locale locale, String text) async {
    final found = await _platform.fetchSpellCheckSuggestions(locale, text);
    if (found == null) return null;

    controller.receiveSpellCheck(text, found);
    return const [];
  }
}
