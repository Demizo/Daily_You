import 'package:daily_you/utils/markdown_preview_scanner.dart';
import 'package:daily_you/utils/markdown_preview_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const styles = MarkdownPreviewStyles(
    marker: Color(0xFF111111),
    link: Color(0xFF222222),
    quote: Color(0xFF333333),
    misspelling: Color(0xFF666666),
    codeBackground: Color(0xFF555555),
    highlightBackground: Color(0xFF777777),
  );
  const baseStyle = TextStyle(fontSize: 16);

  List<TextSpan> build(
    String text, {
    TextRange composing = TextRange.empty,
    List<TextRange> misspellings = const [],
  }) {
    final span = buildMarkdownPreviewSpan(
      text: text,
      spans: scanMarkdown(text).spans,
      baseStyle: baseStyle,
      styles: styles,
      composing: composing,
      misspellings: misspellings,
    );
    return (span.children ?? const <TextSpan>[]).cast<TextSpan>();
  }

  String joined(List<TextSpan> children) =>
      children.map((child) => child.text).join();

  test('plain text stays one unstyled span', () {
    final children = build('Woke up late.');

    expect(children, hasLength(1));
    expect(children.single.text, 'Woke up late.');
    expect(children.single.style, baseStyle);
  });

  test('bold splits into marker, content and marker', () {
    final children = build('**loud**');

    expect(children.map((child) => child.text).toList(), ['**', 'loud', '**']);
    expect(children.first.style!.color, styles.marker);
    expect(children[1].style!.fontWeight, FontWeight.bold);
    expect(children[1].style!.color, isNull);
  });

  test('nested constructs merge their styles', () {
    final children = build('# **T**');

    expect(joined(children), '# **T**');
    final hashes = children.first;
    expect(hashes.text, '#');
    expect(hashes.style!.color, styles.marker);
    expect(hashes.style!.fontSize, 24);

    final boldMarker = children.firstWhere((child) => child.text == '**');
    expect(boldMarker.style!.fontSize, 24);
    expect(boldMarker.style!.color, styles.marker);

    final title = children.firstWhere((child) => child.text == 'T');
    expect(title.style!.fontSize, 24);
    expect(title.style!.fontWeight, FontWeight.bold);
  });

  test('the quote marker shrinks against the bar that replaces it', () {
    final children = build('> quoted');

    expect(children.first.text, '>');
    expect(children.first.style!.fontSize, 12);
    expect(children.last.style!.fontSize, 16);
    expect(children.last.style!.color, styles.quote);
  });

  test('the bullet marker is drawn heavier than the item', () {
    final children = build('- milk');

    expect(children.first.text, '-');
    expect(children.first.style!.fontWeight, FontWeight.bold);
    expect(children.first.style!.color, styles.marker);
    expect(children.last.style!.fontWeight, isNull);
  });

  test('every character survives the styling pass', () {
    const text = '- a **b** `c`\n> [d](e)\n```\nf\n```';

    expect(joined(build(text)), text);
  });

  test('the composing range is underlined without losing its styling', () {
    final children =
        build('**loud**', composing: const TextRange(start: 2, end: 4));

    final composing = children.firstWhere((child) => child.text == 'lo');
    expect(composing.style!.fontWeight, FontWeight.bold);
    expect(composing.style!.decoration, TextDecoration.underline);

    final rest = children.firstWhere((child) => child.text == 'ud');
    expect(rest.style!.decoration, isNull);
  });

  test('a misspelling is underlined without losing its styling', () {
    final children =
        build('**wrng** ok', misspellings: const [TextRange(start: 2, end: 6)]);

    final flagged = children.firstWhere((child) => child.text == 'wrng');
    expect(flagged.style!.fontWeight, FontWeight.bold);
    expect(flagged.style!.decorationStyle, TextDecorationStyle.wavy);
    expect(flagged.style!.decorationColor, styles.misspelling);

    final rest = children.firstWhere((child) => child.text == ' ok');
    expect(rest.style!.decoration, isNull);
  });
}
