import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

// Fixes duplicate scaling issues with markdown_widget
// See: https://github.com/asjqkkkk/markdown_widget/issues/208
class ScaledMarkdown extends StatelessWidget {
  final String data;
  final int? maxCharacters;
  final double scaleFactor;
  final bool compact;

  const ScaledMarkdown({
    super.key,
    required this.data,
    this.maxCharacters,
    this.scaleFactor = 1,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String text = data;

    if (maxCharacters != null && text.length > maxCharacters!) {
      text = "${text.substring(0, maxCharacters)}…";
    }

    // Get the device's current text scaling to respect user settings
    final deviceScaler = MediaQuery.textScalerOf(context);
    // Apply custom scaling to the user's text scale
    final customScaler = TextScaler.linear(deviceScaler.scale(scaleFactor));

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

            final child = Text.rich(
              span,
              textScaler:
                  shouldIgnoreTextScaler ? TextScaler.noScaling : customScaler,
            );

            return shouldIgnoreTextScaler
                ? child
                : _WithTextScalar(child: child);
          });
        },
        linesMargin: compact
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: 8, top: 2),
      ),
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
