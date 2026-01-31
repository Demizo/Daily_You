import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

// Fixes duplicate scaling issues with markdown_widget
// See: https://github.com/asjqkkkk/markdown_widget/issues/208
class ScaledMarkdown extends StatelessWidget {
  final String data;
  const ScaledMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBlock(
      config: theme.brightness == Brightness.light
          ? MarkdownConfig.defaultConfig
          : MarkdownConfig.darkConfig,
      generator: MarkdownGenerator(richTextBuilder: (span) {
        return Builder(builder: (context) {
          final shouldIgnoreTextScaler =
              context.getInheritedWidgetOfExactType<_WithTextScalar>() != null;
          final child = Text.rich(span);
          return shouldIgnoreTextScaler
              ? MediaQuery.withNoTextScaling(child: child)
              : _WithTextScalar(child: child);
        });
      }),
      data: data,
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
