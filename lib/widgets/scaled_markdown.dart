import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

// Fixes duplicate scaling issues with markdown_widget
// See: https://github.com/asjqkkkk/markdown_widget/issues/208
class ScaledMarkdown extends StatelessWidget {
  final String data;
  final int? maxCharacters;
  const ScaledMarkdown({super.key, required this.data, this.maxCharacters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String text = data;

    if (maxCharacters != null && text.length > maxCharacters!) {
      text = "${text.substring(0, maxCharacters)}…";
    }

    return MarkdownBlock(
      config: theme.brightness == Brightness.light
          ? MarkdownConfig.defaultConfig
          : MarkdownConfig.darkConfig,
      generator: MarkdownGenerator(
          richTextBuilder: (span) {
            return Builder(builder: (context) {
              final shouldIgnoreTextScaler =
                  context.getInheritedWidgetOfExactType<_WithTextScalar>() !=
                      null;
              final child = Text.rich(span);
              return shouldIgnoreTextScaler
                  ? MediaQuery.withNoTextScaling(child: child)
                  : _WithTextScalar(child: child);
            });
          },
          linesMargin: EdgeInsets.only(bottom: 8, top: 2)),
      data: text,
    );
  }
}

class _WithTextScalar extends InheritedWidget {
  const _WithTextScalar({required super.child});

  @override
  bool updateShouldNotify(covariant _WithTextScalar oldWidget) {
    return false;
  }
}
